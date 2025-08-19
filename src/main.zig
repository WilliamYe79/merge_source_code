const std = @import("std");
const fs = std.fs;
const io = std.io;
const process = std.process;
const print = std.debug.print;

const Config = struct {
    root_dir: []const u8 = "",
    suffixes: []const []const u8 = &[_][]const u8{},
    encoding: []const u8 = "UTF-8",
    output_file: []const u8 = "merged_source_code.txt",
};

const FileEntry = struct {
    relative_path: []u8,
    content: []u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const config = try parseArgs(allocator);
    defer allocator.free(config.suffixes);

    // Validate root directory exists
    var root_dir = try fs.openDirAbsolute(config.root_dir, .{ .iterate = true });
    defer root_dir.close();

    // Collect all matching files
    var files = std.ArrayList(FileEntry).init(allocator);
    defer {
        for (files.items) |entry| {
            allocator.free(entry.relative_path);
            allocator.free(entry.content);
        }
        files.deinit();
    }

    try collectFiles(allocator, root_dir, config.root_dir, "", config.suffixes, &files);

    // Sort files by path for consistent output
    std.mem.sort(FileEntry, files.items, {}, compareFileEntries);

    // Write merged content to output file
    try writeMergedFile(allocator, config.output_file, files.items);

    print("Successfully merged {d} files into {s}\n", .{ files.items.len, config.output_file });
}

fn parseArgs(allocator: std.mem.Allocator) !Config {
    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    var config = Config{};
    var suffixes_list = std.ArrayList([]const u8).init(allocator);
    defer suffixes_list.deinit();

    // Skip program name
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-d")) {
            if (args.next()) |dir| {
                config.root_dir = dir;
            } else {
                print("Error: -d requires a directory path\n", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "-suffix")) {
            if (args.next()) |suffix_str| {
                var it = std.mem.tokenize(u8, suffix_str, ",");
                while (it.next()) |suffix| {
                    const suffix_copy = try allocator.dupe(u8, suffix);
                    try suffixes_list.append(suffix_copy);
                }
            } else {
                print("Error: -suffix requires a comma-separated list of extensions\n", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "-encoding")) {
            if (args.next()) |encoding| {
                config.encoding = encoding;
            } else {
                print("Error: -encoding requires an encoding name\n", .{});
                std.process.exit(1);
            }
        } else if (std.mem.eql(u8, arg, "-o")) {
            if (args.next()) |output| {
                config.output_file = output;
            } else {
                print("Error: -o requires an output file path\n", .{});
                std.process.exit(1);
            }
        }
    }

    // Validate required arguments
    if (config.root_dir.len == 0) {
        print("Error: -d (directory) argument is required\n", .{});
        print("Usage: merge_source_code -d <directory> -suffix <ext1,ext2,...> [-encoding <encoding>] [-o <output_file>]\n", .{});
        std.process.exit(1);
    }

    if (suffixes_list.items.len == 0) {
        print("Error: -suffix argument is required\n", .{});
        print("Usage: merge_source_code -d <directory> -suffix <ext1,ext2,...> [-encoding <encoding>] [-o <output_file>]\n", .{});
        std.process.exit(1);
    }

    config.suffixes = try suffixes_list.toOwnedSlice();
    return config;
}

fn collectFiles(
    allocator: std.mem.Allocator,
    dir: fs.Dir,
    root_path: []const u8,
    relative_path: []const u8,
    suffixes: []const []const u8,
    files: *std.ArrayList(FileEntry),
) !void {
    var iterator = dir.iterate();

    while (try iterator.next()) |entry| {
        const entry_relative_path = if (relative_path.len > 0)
            try std.fmt.allocPrint(allocator, "{s}/{s}", .{ relative_path, entry.name })
        else
            try allocator.dupe(u8, entry.name);
        defer allocator.free(entry_relative_path);

        switch (entry.kind) {
            .file => {
                // Check if file has matching suffix
                if (hasMatchingSuffix(entry.name, suffixes)) {
                    // Read file content
                    const file = try dir.openFile(entry.name, .{});
                    defer file.close();

                    const file_size = try file.getEndPos();
                    const content = try allocator.alloc(u8, file_size);
                    _ = try file.read(content);

                    try files.append(.{
                        .relative_path = try allocator.dupe(u8, entry_relative_path),
                        .content = content,
                    });
                }
            },
            .directory => {
                // Recursively process subdirectory
                var sub_dir = try dir.openDir(entry.name, .{ .iterate = true });
                defer sub_dir.close();

                try collectFiles(allocator, sub_dir, root_path, entry_relative_path, suffixes, files);
            },
            else => {},
        }
    }
}

fn hasMatchingSuffix(filename: []const u8, suffixes: []const []const u8) bool {
    for (suffixes) |suffix| {
        const ext = std.fmt.allocPrint(std.heap.page_allocator, ".{s}", .{suffix}) catch continue;
        defer std.heap.page_allocator.free(ext);

        if (std.mem.endsWith(u8, filename, ext)) {
            return true;
        }
    }
    return false;
}

fn compareFileEntries(context: void, a: FileEntry, b: FileEntry) bool {
    _ = context;
    return std.mem.lessThan(u8, a.relative_path, b.relative_path);
}

fn writeMergedFile(_: std.mem.Allocator, output_path: []const u8, files: []const FileEntry) !void {
    const file = try fs.cwd().createFile(output_path, .{});
    defer file.close();

    var buffered_writer = io.bufferedWriter(file.writer());
    const writer = buffered_writer.writer();

    for (files, 0..) |entry, i| {
        // Write file path
        try writer.print("{s}:\n", .{entry.relative_path});

        // Determine language for syntax highlighting
        const lang = getLanguageFromPath(entry.relative_path);

        // Write code block
        try writer.print("```{s}\n", .{lang});
        try writer.writeAll(entry.content);

        // Ensure content ends with newline before closing code block
        if (entry.content.len == 0 or entry.content[entry.content.len - 1] != '\n') {
            try writer.writeByte('\n');
        }
        try writer.writeAll("```\n");

        // Add extra newline between files (except after last file)
        if (i < files.len - 1) {
            try writer.writeByte('\n');
        }
    }

    try buffered_writer.flush();
}

fn getLanguageFromPath(path: []const u8) []const u8 {
    if (std.mem.endsWith(u8, path, ".java")) return "java";
    if (std.mem.endsWith(u8, path, ".properties")) return "properties";
    if (std.mem.endsWith(u8, path, ".xml")) return "xml";
    if (std.mem.endsWith(u8, path, ".json")) return "json";
    if (std.mem.endsWith(u8, path, ".yaml") or std.mem.endsWith(u8, path, ".yml")) return "yaml";
    if (std.mem.endsWith(u8, path, ".py")) return "python";
    if (std.mem.endsWith(u8, path, ".js")) return "javascript";
    if (std.mem.endsWith(u8, path, ".ts")) return "typescript";
    if (std.mem.endsWith(u8, path, ".c")) return "c";
    if (std.mem.endsWith(u8, path, ".cpp") or std.mem.endsWith(u8, path, ".cc")) return "cpp";
    if (std.mem.endsWith(u8, path, ".h") or std.mem.endsWith(u8, path, ".hpp")) return "cpp";
    if (std.mem.endsWith(u8, path, ".rs")) return "rust";
    if (std.mem.endsWith(u8, path, ".go")) return "go";
    if (std.mem.endsWith(u8, path, ".zig")) return "zig";
    if (std.mem.endsWith(u8, path, ".sql")) return "sql";
    if (std.mem.endsWith(u8, path, ".sh")) return "bash";
    if (std.mem.endsWith(u8, path, ".md")) return "markdown";
    if (std.mem.endsWith(u8, path, ".html")) return "html";
    if (std.mem.endsWith(u8, path, ".css")) return "css";
    if (std.mem.endsWith(u8, path, ".scss") or std.mem.endsWith(u8, path, ".sass")) return "scss";
    if (std.mem.endsWith(u8, path, ".gradle")) return "gradle";
    if (std.mem.endsWith(u8, path, ".kt")) return "kotlin";
    if (std.mem.endsWith(u8, path, ".swift")) return "swift";
    if (std.mem.endsWith(u8, path, ".rb")) return "ruby";
    if (std.mem.endsWith(u8, path, ".php")) return "php";
    if (std.mem.endsWith(u8, path, ".r")) return "r";
    if (std.mem.endsWith(u8, path, ".m")) return "matlab";
    if (std.mem.endsWith(u8, path, ".lua")) return "lua";
    if (std.mem.endsWith(u8, path, ".vim")) return "vim";
    if (std.mem.endsWith(u8, path, ".dockerfile") or std.mem.endsWith(u8, path, "Dockerfile")) return "dockerfile";
    if (std.mem.endsWith(u8, path, ".toml")) return "toml";
    if (std.mem.endsWith(u8, path, ".ini")) return "ini";
    if (std.mem.endsWith(u8, path, ".csv")) return "csv";
    if (std.mem.endsWith(u8, path, ".txt")) return "text";

    // Default fallback
    return "text";
}
