pub const root = @import("./cuid2.zig");

test {
    @import("std").testing.refAllDecls(@This());
}

test "histogram" {
    try @import("./test/histogram.zig").generateHistogram(100_000);
}
