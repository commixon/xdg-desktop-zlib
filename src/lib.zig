pub const Parser = @import("Parser.zig");
pub const Desktop = @import("Desktop.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
