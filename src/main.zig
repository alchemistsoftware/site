const std = @import("std");

const public_path = "public";
const pages_path = "public/pages";
const templates_path = "templates";
const template_buffer_size = 1024 * 20;

const splash =
    \\================================
    \\* Static Site Generator v0.0.5 *
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
    \\<div class="right-left-margin-container">
    //   \\    <h1 class="fancy-header">calebarg.net</h1>
    \\    <nav class="navbar">
    \\        <a href="/index.html">Home</a>
    \\        <a href="/pages/resume.html">Resume</a>
    \\        <a href="/pages/projects.html">Projects</a>
    \\        <a href="/pages/posts.html">Posts</a>
    \\        <a href="https://github.com/cabarger">Github</a>
    \\        <a href="https://twitter.com/calebbarger20">@calebbarger20</a>
    \\    </nav>
    \\</div>
    \\
;

const raw_copyright_html =
    \\<div id="copyright-container"><p>Copyright Alchemist Software LLC 2023-2024</p></div>
    \\
;

fn write_top_html_chunk(page_writer: std.fs.File.Writer) !void {
    try page_writer.writeAll("<!DOCTYPE html>\n");
    try page_writer.writeAll("<html lang=\"en\">\n");
    try page_writer.writeAll(raw_head_html);
    try page_writer.writeAll("<body>\n");
    try page_writer.writeAll(raw_navbar_html);
}

fn write_bottom_html_chunk(page_writer: std.fs.File.Writer) !void {
    //try page_writer.writeAll(raw_copyright_html);
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

    try stdout.print("Removing {s}...\n", .{pages_path});
    try std.fs.cwd().deleteTree(pages_path);
    var pages_d = try std.fs.cwd().makeOpenPath(pages_path, .{});
    defer pages_d.close();

    const template_byte_buffer = try arena.alloc(u8, template_buffer_size);

    // Gen index.html
    {
        var public_d = try std.fs.cwd().openDir(public_path, .{});
        const index_f = try public_d.createFile("index.html", .{});
        defer index_f.close();
        const index_writer = index_f.writer();

        try write_top_html_chunk(index_writer);

        try index_writer.writeAll("<div id=\"canvas-container\"><canvas id=\"canvas\" width=\"500em\" height=\"600em\"></canvas></div>");
        try index_writer.writeAll("<h2 class=\"sub-header\">Caleb activity</h2>");
        try index_writer.writeAll("<div id=\"activity\"></div>");

        const template_bytes = try templates_d.readFile("shite_script.html", template_byte_buffer);
        try index_writer.writeAll(template_bytes);

        try write_bottom_html_chunk(index_writer);
    }

    // Gen posts.html
    {
        var posts_d = try templates_d.openDir("./posts", .{.iterate = true});
        defer posts_d.close();
        const posts_f = try pages_d.createFile("posts.html", .{});
        defer posts_f.close();

        const posts_writer = posts_f.writer();
        try write_top_html_chunk(posts_writer);
        try posts_writer.writeAll("<div class=\"template-container\"><ul id=\"posts\">");

        var posts_d_walker = try posts_d.walk(arena);
        while (try posts_d_walker.next()) |walk_entry| {
            switch (walk_entry.kind) {
                .file => {
                    try posts_writer.writeAll("<li><a href=\"/pages/posts/");
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

    var template_d_walker = try templates_d.walk(arena);
    while (try template_d_walker.next()) |walk_entry| {
        switch (walk_entry.kind) {
            .directory => {
                try stdout.print("Making path {s}/{s}...\n", .{ pages_path, walk_entry.path });
                try pages_d.makePath(walk_entry.path);
            },
            .file => {
                try stdout.print("Writing {s}/{s}...\n", .{ pages_path, walk_entry.path });
                const template_bytes = try templates_d.readFile(walk_entry.path, template_byte_buffer);
                const page_f = try pages_d.createFile(walk_entry.path, .{});
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
