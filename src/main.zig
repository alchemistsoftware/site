const std = @import("std");

const public_path = "public";
const templates_path = "templates";
const template_buffer_size = 1024 * 20;

const splash =
    \\================================
    \\* Static Site Generator v0.0.6 *
    \\================================
    \\
;

const raw_head_html =
    \\<head>
    \\    <meta charset="UTF-8">
    \\    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    \\    <meta name="description" content="">
    \\    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    \\    <meta http-equiv="Pragma" content="no-cache">
    \\    <title>calebarg.net</title>
    \\    <link rel="icon" href="./favicon.ico" type="image/x-icon">
    \\    <link rel="stylesheet" href="/style.css">
    \\</head>
    \\
;

const raw_navbar_html =
    \\    <nav class="navbar">
    \\        <a href="/index.html">Home</a>
    \\        <a href="/projects.html">Projects</a>
    \\        <a href="/posts.html">Posts</a>
    \\        <a href="https://github.com/calebarg">Github</a>
    \\        <a href="https://twitter.com/calebbarger20">@calebbarger20</a>
    \\        <a href="/resume.html">Resume</a>
    \\        <a href="/tetris.html">Tetris</a>
    \\    </nav>
;

fn write_top_html_chunk(page_writer: std.fs.File.Writer) !void {
    try page_writer.writeAll("<!DOCTYPE html>\n");
    try page_writer.writeAll("<html lang=\"en\">\n");
    try page_writer.writeAll(raw_head_html);
    try page_writer.writeAll("<body>\n");
    try page_writer.writeAll("<div id=\"navbar-container\">");
    try page_writer.writeAll(raw_navbar_html);
    try page_writer.writeAll("<img id=\"profile\" src=\"/assets/profile.jpg\">");
    try page_writer.writeAll("</div>");
}

fn write_bottom_html_chunk(page_writer: std.fs.File.Writer) !void {
    try page_writer.writeAll("</body>\n");
    try page_writer.writeAll("</html>\n");
}

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    defer arena_instance.deinit();

    const stdout_f = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_f);
    const stdout = bw.writer();

    try stdout.writeAll("\n" ++ splash);

    var templates_d = try std.fs.cwd().openDir(templates_path, .{ .iterate = true });
    defer templates_d.close();

    var public_d = try std.fs.cwd().openDir(public_path, .{ .iterate = true });
    defer public_d.close();

    var posts_d = try templates_d.openDir("./posts", .{.iterate = true});
    defer posts_d.close();

    const template_byte_buffer = try arena.alloc(u8, template_buffer_size);

    // Gen posts.html
    {
        const posts_f = try public_d.createFile("posts.html", .{});
        defer posts_f.close();

        const posts_writer = posts_f.writer();
        try write_top_html_chunk(posts_writer);
        try posts_writer.writeAll("<div class=\"template-container\"><ul id=\"posts\">");

        var posts_d_walker = try posts_d.walk(arena);
        while (try posts_d_walker.next()) |walk_entry| {
            switch (walk_entry.kind) {
                .file => {
                    try posts_writer.writeAll("<li><a href=\"/posts/");
                    try posts_writer.writeAll(walk_entry.basename);
                    try posts_writer.writeAll("\">");
                    try posts_writer.writeAll(std.fs.path.stem(walk_entry.basename));
                    try posts_writer.writeAll("</li>");
                },
                else => continue,
            }
        }
        try posts_writer.writeAll("</ul></div>");
        try write_bottom_html_chunk(posts_writer);
    }

    // Gen index.html - Show the contents of the latest post
    {
        const index_f = try public_d.createFile("index.html", .{});
        defer index_f.close();
        const index_writer = index_f.writer();

        try write_top_html_chunk(index_writer);

        try index_writer.writeAll("<div class=\"template-container\">");

        try index_writer.writeAll("<h3>[About me]</h3>");
        try index_writer.writeAll("<p>Handmade software!</p>");


        try index_writer.writeAll("<h3>[Latest post]</h3>");

        var posts_d_walker = try posts_d.walk(arena);
        var latest_post_path: ?[]const u8 = null;
        var latest = @Vector(3, u16){0, 0, 0};
        while (try posts_d_walker.next()) |walk_entry| {
            switch (walk_entry.kind) {
                .file => {
                    const basename_no_ext = std.fs.path.stem(walk_entry.basename);
                    var iter = std.mem.splitSequence(u8, basename_no_ext, "-");
                    _ = iter.next() orelse unreachable;
                    const year = try std.fmt.parseInt(u16, iter.next() orelse unreachable, 10);
                    const month = try std.fmt.parseInt(u16, iter.next() orelse unreachable, 10);
                    const day = try std.fmt.parseInt(u16, iter.next() orelse unreachable, 10);

                    var is_latest_post = false;
                    const date = @Vector(3, u16){year, month, day};
                    const date_gt = date > latest;
                    const date_eq = date == latest;

                    if (date_gt[0]) { // Curr year > latest year
                        is_latest_post = true;
                    }
                    else if (date_eq[0]) { // Curr year == latest year
                        if (date_gt[1]) {  // Curr month > latest month
                            is_latest_post = true;
                        }
                        else if (date_eq[1]) { // Curr month == latest month
                            if (date_gt[2]) { // Curr day > latest day
                                is_latest_post = true;
                            }
                        }
                    }

                    if (is_latest_post) {
                        latest = date;
                        latest_post_path = try arena.dupe(u8, walk_entry.path);
                    }
                },
                else => continue,
            }
        }


        const latest_post_contents = try posts_d.readFile(latest_post_path orelse unreachable, template_byte_buffer);
        try index_writer.writeAll(latest_post_contents);

        try index_writer.writeAll("</div>"); // Template container closing div

        try write_bottom_html_chunk(index_writer);
    }

    var template_d_walker = try templates_d.walk(arena);
    while (try template_d_walker.next()) |walk_entry| {
        switch (walk_entry.kind) {
            .directory => {
                try stdout.print("Making path {s}/{s}...\n", .{ public_path, walk_entry.path });
                try public_d.makePath(walk_entry.path);
            },
            .file => {
                try stdout.print("Writing {s}/{s}...\n", .{ public_path, walk_entry.path });
                const template_bytes = try templates_d.readFile(walk_entry.path, template_byte_buffer);
                const page_f = try public_d.createFile(walk_entry.path, .{});
                defer page_f.close();
                const page_writer = page_f.writer();

                try write_top_html_chunk(page_writer);
                try page_writer.writeAll("<div class=\"template-container\">");
                try page_writer.writeAll(template_bytes);
                try page_writer.writeAll("</div>");
                try write_bottom_html_chunk(page_writer);
            },
            else => continue,
        }
    }

    try bw.flush();
    std.process.cleanExit();
}
