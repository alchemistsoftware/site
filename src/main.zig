const std = @import("std");

const pages_path = "public/pages";
const templates_path = "templates";
const template_buffer_size = 1024 * 8;

const splash =
    \\================================
    \\* Static Site Generator v0.0.2 *
    \\================================
    \\
;

const raw_head_html =
    \\<head>
    \\    <meta charset="UTF-8">
    \\    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    \\    <meta name="description" content="">
    \\    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    \\    <title>Alchemist Software</title>
    \\    <link rel="icon" href="./favicon.ico" type="image/x-icon">
    \\    <link rel="stylesheet" href="/style.css">
    \\</head>
    \\
;

const raw_navbar_html =
    \\<div class="right-left-margin-container">
    \\    <h1 class="fancy-header">Alchemist Software</h1>
    \\    <nav class="navbar">
    \\        <a href="/index.html">Home</a>
    \\        <a href="/pages/resume.html">Resume</a>
    \\        <a href="/pages/projects.html">Projects</a>
    \\        <a href="https://github.com/cabarger">Github</a>
    \\    </nav>
    \\</div>
    \\
;

const raw_copyright_html =
    \\<div id="copyright-container"><p>Copyright Alchemist Software LLC 2023</p></div>
    \\
;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    defer arena_instance.deinit();

    const stdout_f = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_f);
    const stdout = bw.writer();

    try stdout.writeAll(splash);

    var templates_d = try std.fs.cwd().openIterableDir(templates_path, .{});
    defer templates_d.close();

    try stdout.print("Nuking {s}...\n", .{pages_path});
    try std.fs.cwd().deleteTree(pages_path);
    var pages_d = try std.fs.cwd().makeOpenPath(pages_path, .{});
    defer pages_d.close();

    var template_byte_buffer = try arena.alloc(u8, template_buffer_size);

    var template_d_walker = try templates_d.walk(arena);
    while (try template_d_walker.next()) |walk_entry| {
        switch (walk_entry.kind) {
            .directory => {
                try stdout.print("Making path {s}/{s}...\n", .{ pages_path, walk_entry.path });
                try pages_d.makePath(walk_entry.path);
            },
            .file => {
                try stdout.print("Writing {s}/{s}...\n", .{ pages_path, walk_entry.path });
                const template_bytes = try templates_d.dir.readFile(walk_entry.path, template_byte_buffer);
                const page_f = try pages_d.createFile(walk_entry.path, .{});
                defer page_f.close();
                const page_writer = page_f.writer();
                try page_writer.writeAll("<!DOCTYPE html>\n");
                try page_writer.writeAll("<html lang=\"en\">\n");
                try page_writer.writeAll(raw_head_html);
                try page_writer.writeAll("<body>\n");
                try page_writer.writeAll(raw_navbar_html);
                try page_writer.writeAll("<div class=\"template-container\">");
                try page_writer.writeAll(template_bytes);
                try page_writer.writeAll("</div>");
                try page_writer.writeAll(raw_copyright_html);
                try page_writer.writeAll("</body>\n");
                try page_writer.writeAll("</html>\n");
            },
            else => continue,
        }
    }

    try bw.flush();
    std.process.cleanExit();
}
