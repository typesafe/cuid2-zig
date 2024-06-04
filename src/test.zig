pub const root = @import("./cuid2.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
