const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const whitespace = std.ascii.whitespace;

const Parser = @This();
const Desktop = @import("Desktop.zig");
const Entry = Desktop.Entry;
const KeyValue = Desktop.KeyValue;

const ParseState = enum {
    header,
    property,
};

pub const Line = union(enum) {
    header: []const u8,
    property: KeyValue,
    empty: bool,
    comment: bool,
    invalid: bool,
};

allocator: Allocator,
entries: *ArrayList(Entry),

pub fn init(gpa: Allocator, entries: *ArrayList(Entry)) Parser {
    return Parser{
        .allocator = gpa,
        .entries = entries,
    };
}

pub fn deinit(self: *Parser) void {
    for (self.entries.items) |*entry| {
        entry.deinit(self.allocator);
    }
    self.entries.deinit(self.allocator);
}

pub fn parse(self: *Parser, source: []const u8) !void {
    var current_entry = Entry{
        .header = "",
        .kvs = .empty,
    };
    errdefer current_entry.deinit(self.allocator);

    var state: ?ParseState = null;
    var lines = std.mem.splitScalar(u8, source, '\n');

    while (lines.next()) |l| {
        const line = parse_line(l);
        switch (line) {
            .empty => continue,
            .comment => continue,
            .invalid => return error.Invalid,
            .header => {
                // On first hit of header, assign to current_entry
                if (state == null) {
                    current_entry.header = line.header;
                    state = .header;
                    continue;
                }
                // On every other hit, we are finished. Append current_entry
                // and reinitiate a new empty one.
                try self.entries.append(self.allocator, current_entry);
                current_entry = Entry{
                    .header = line.header,
                    .kvs = .empty,
                };
                state = .header;
                continue;
            },
            .property => {
                const kv = KeyValue{
                    .key = line.property.key,
                    .value = line.property.value,
                };
                try current_entry.kvs.append(self.allocator, kv);
                state = .property;
                continue;
            },
        }
    }

    if (state == .property) {
        try self.entries.append(self.allocator, current_entry);
    }

    if (state == .header) {
        return error.Invalid;
    }
}

fn parse_line(buf: []const u8) Line {
    const line = std.mem.trim(u8, buf, &whitespace);
    if (line.len == 0) return Line{ .empty = true };

    if (std.mem.startsWith(u8, line, "#")) return Line{ .comment = true };

    if (std.mem.startsWith(u8, line, "[") and std.mem.endsWith(u8, line, "]")) {
        return Line{
            .header = line[1 .. line.len - 1],
        };
    }

    if (std.mem.indexOfScalar(u8, line, '=')) |index| {
        return Line{ .property = KeyValue{
            .key = std.mem.trim(u8, line[0..index], &whitespace),
            .value = std.mem.trim(u8, line[index + 1 ..], &whitespace),
        } };
    }

    return Line{ .invalid = true };
}
