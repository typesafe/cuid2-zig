//! Generates random values to support Cuid2.

const std = @import("std");
const testing = std.testing;

// We need a "stable pointer", maybe there's a better way, but it does the trick
var prng: ?std.rand.DefaultPrng = null;

/// A custom function that generates a f64 value in the range `[0, 1)`.
pub const RandomFn = *const fn () f64;

const Self = @This();

randomFn: ?RandomFn,
rnd: ?std.Random,

pub fn init(randomFn: ?RandomFn) Self {
    if (randomFn == null and prng == null) {
        const seed = @as(u64, @bitCast(std.time.milliTimestamp()));
        prng = std.rand.DefaultPrng.init(seed);
    }

    const rnd = if (randomFn != null) null else prng.?.random();
    //std.debug.print("{}", .{rnd.?.float(f32)});
    return .{
        .randomFn = randomFn,
        .rnd = rnd,
    };
}

/// Returns a random character from the alphabet.
pub fn aplpha(self: Self) u8 {
    return self.int(u8, 26) + 'a';
}

/// Returns a floating point value evenly distributed in the range `[0, 1)`.
pub fn float(self: Self) f64 {
    if (self.randomFn) |f| {
        const v = f();

        if (v < 0 or v >= 1) {
            std.debug.print("Custom RandomFn returned {}, value must be in the range [0,1), panicking...", .{v});
            @panic("Customer RandomFn returned invalid value, see debug output.");
        }

        return v;
    }

    return self.rnd.?.float(f64);
}

/// Returns an integer values in the range `[0, base)`.
pub fn int(self: Self, comptime T: type, base: T) T {
    return @intFromFloat(@floor(self.float() * @as(f64, @floatFromInt(base))));
}

/// Returns a random base36 string of the specified length.
pub fn base63(self: Self, comptime size: u8) [size]u8 {
    var buf: [size]u8 = undefined;
    var offset: usize = 0;

    while (offset < size) {
        // base 36 results in a single char, so we won't ever overflow here...
        offset += std.fmt.formatIntBuf(buf[offset..], self.int(u8, 36), 36, .lower, .{});
    }

    return buf;
}

// these tests mainly drove the development...

test "Random.int()" {
    const r = Self.init(null);

    for (0..200) |_| {
        const a = r.int(u32, 100);
        try testing.expect(a >= 0 and a < 100);
    }
}

test "Random.base36()" {
    const r = Self.init(null);

    try testing.expectEqual(100, r.base63(100).len);
    try testing.expectEqual(10, r.base63(10).len);
}

test "Random.alpha()" {
    const r = Self.init(null);

    for (0..200) |_| {
        const a = r.aplpha();
        try testing.expect(a >= 'a' and a <= 'z');
    }
}

test "Random.alpha() with customer RandomFn" {
    try testing.expectEqual('a', Self.init(customRandomFn(0)).aplpha());
    try testing.expectEqual('n', Self.init(customRandomFn(0.5)).aplpha());
    try testing.expectEqual('z', Self.init(customRandomFn(0.999)).aplpha());
}

test "Random.base36() with customer RandomFn" {
    try testing.expectEqualStrings("00000", &Self.init(customRandomFn(0)).base63(5));
    try testing.expectEqualStrings("iiiii", &Self.init(customRandomFn(0.5)).base63(5));
    try testing.expectEqualStrings("zzzzz", &Self.init(customRandomFn(0.999)).base63(5));
}

fn customRandomFn(comptime fixedValue: f64) RandomFn {
    return struct {
        fn rnd() f64 {
            return fixedValue;
        }
    }.rnd;
}
