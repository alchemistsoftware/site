const std = @import("std");

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
    \\        <a href="/pages/posts.html">Posts</a>
    \\        <a href="/pages/projects.html">Projects</a>
    \\        <a href="/pages/about.html">About</a>
    \\        <a href="/pages/contact.html">Contact</a>
    \\    </nav>
    \\</div>
    \\
;

const raw_copyright_html =
    \\<p id="copyright">Copyright Alchemist Software LLC 2023</p>
    \\
;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    defer arena_instance.deinit();

    var templates_d = try std.fs.cwd().openIterableDir("templates", .{});
    defer templates_d.close();

    try std.fs.cwd().deleteTree("public/pages");
    var pages_d = try std.fs.cwd().makeOpenPath("public/pages", .{});
    defer pages_d.close();

    var template_d_walker = try templates_d.walk(arena);
    while (try template_d_walker.next()) |walk_entry| {
        std.debug.print("Writing ./public/posts/{s}...\n", .{walk_entry.path});

        if (walk_entry.kind == .Directory) {
            try pages_d.makePath(walk_entry.path);
            continue;
        }

        const template_bytes = try templates_d.dir.readFileAlloc(arena, walk_entry.path, 1024 * 10);

        const page_f = try pages_d.createFile(walk_entry.path, .{});
        defer page_f.close();
        const page_writer = page_f.writer();

        try page_writer.writeAll("<!DOCTYPE html>\n");
        try page_writer.writeAll("<html lang=\"en\">\n");
        try page_writer.writeAll(raw_head_html);
        try page_writer.writeAll("<body>\n");
        try page_writer.writeAll(raw_navbar_html);
        try page_writer.writeAll(template_bytes);
        try page_writer.writeAll(raw_copyright_html);
        try page_writer.writeAll("</body>\n");
        try page_writer.writeAll("</html>\n");
    }

    std.process.cleanExit();
}
