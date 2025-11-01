const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const whitespace = std.ascii.whitespace;

const Desktop = @This();

pub const KeyValue = struct {
    key: []const u8,
    value: []const u8,

    pub fn deinit(self: *KeyValue, allocator: Allocator) void {
        _ = allocator;
        _ = self;
    }
};

pub const Entry = struct {
    header: []const u8,
    kvs: ArrayList(KeyValue),

    pub fn deinit(self: *Entry, allocator: Allocator) void {
        self.kvs.deinit(allocator);
    }
};
