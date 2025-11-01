const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const Parser = @import("Parser.zig");
const Desktop = @import("Desktop.zig");
const Entry = Desktop.Entry;
const KeyValue = Desktop.KeyValue;

test "valid entry flat parse" {
    const allocator = std.testing.allocator;

    var expected = Entry{
        .header = "Default Entry",
        .kvs = .empty,
    };
    try expected.kvs.append(allocator, .{
        .key = "Name",
        .value = "Zen Browser",
    });
    try expected.kvs.append(allocator, .{
        .key = "Comment",
        .value = "Experience tranquillity while browsing the web without people tracking you!",
    });
    try expected.kvs.append(allocator, .{
        .key = "Exec",
        .value = "/opt/zen-browser-bin/zen-bin %u",
    });
    defer expected.deinit(allocator);

    const test_content =
        \\#This is a comment
        \\
        \\[Desktop Entry]
        \\Name=Zen Browser
        \\Comment=Experience tranquillity while browsing the web without people tracking you!
        \\Exec=/opt/zen-browser-bin/zen-bin %u
    ;

    var entries: ArrayList(Entry) = .empty;
    var parser = Parser.init(allocator, &entries);
    defer parser.deinit();
    try parser.parse(test_content);

    try std.testing.expectEqual(entries.items.len, 1);
    const entry = entries.items[0];
    for (entry.kvs.items, 0..) |kv, index| {
        try std.testing.expectEqualStrings(kv.key, expected.kvs.items[index].key);
        try std.testing.expectEqualStrings(kv.value, expected.kvs.items[index].value);
    }
}

test "test empty content" {
    const allocator = std.testing.allocator;
    const test_content = "";
    var entries: ArrayList(Entry) = .empty;
    var parser = Parser.init(allocator, &entries);
    defer parser.deinit();
    try parser.parse(test_content);

    var emptyArray = ArrayList(Entry).empty;
    defer emptyArray.deinit(allocator);
    try std.testing.expectEqual(entries, emptyArray);
}

test "test empty lines and comments" {
    const allocator = std.testing.allocator;
    const test_content =
        \\#This is a comment
        \\
        \\
        \\#And this is another one
    ;
    var entries: ArrayList(Entry) = .empty;
    var parser = Parser.init(allocator, &entries);
    defer parser.deinit();
    try parser.parse(test_content);

    var emptyArray = ArrayList(Entry).empty;
    defer emptyArray.deinit(allocator);
    try std.testing.expectEqual(entries, emptyArray);
}

test "test invalid header" {
    const allocator = std.testing.allocator;
    const test_content =
        \\[Desktop Entry
        \\Name=Invalid
        \\
    ;
    var entries: ArrayList(Entry) = .empty;
    var parser = Parser.init(allocator, &entries);
    defer parser.deinit();
    parser.parse(test_content) catch |e| {
        try std.testing.expectEqual(e, error.Invalid);
    };
}

test "test invalid property" {
    const allocator = std.testing.allocator;
    const test_content =
        \\[Desktop Entry]
        \\Name=Kati
        \\Allo
        \\
    ;
    var entries: ArrayList(Entry) = .empty;
    var parser = Parser.init(allocator, &entries);
    defer parser.deinit();
    parser.parse(test_content) catch |e| {
        try std.testing.expectEqual(e, error.Invalid);
    };
}
