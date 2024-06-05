const std = @import("std");

pub const cuid2 = @import("cuid2");

pub fn main() !void {
    var generator = cuid2.Cuid2(24).init(.{ .random = customRandom });

    std.debug.print("generated id '{s}'\n", .{generator.next()});
}

fn customRandom() f64 {
    return std.crypto.random.float(f64);
}
