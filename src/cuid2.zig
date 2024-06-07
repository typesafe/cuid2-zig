const std = @import("std");
const testing = std.testing;

const Limb = std.math.big.Limb;
const Const = std.math.big.int.Const;
const Mutable = std.math.big.int.Mutable;

const Random = @import("./Random.zig");

// ~22k hosts before 50% chance of initial counter collision
const MaxSessionInitCount: u64 = 476782367;

const MinIdLength: u8 = 2;
const MaxIdLength: u8 = 32;

const Options = struct {
    random: ?Random.RandomFn = null,
};

/// Create a cuid2 generator.
///
/// Parameters:
/// - `length`: a comptime value in range [2, 32] to specify the length of the generated identifiers.s
pub fn Cuid2(comptime length: u8) type {
    if (length < MinIdLength or length > MaxIdLength) {
        @compileError("Invalid idLength. Cuid2 id length must be in the range [2,32].");
    }

    return struct {
        const Self = @This();

        rnd: Random,
        fingerprint: [64]u8,
        counter: std.atomic.Value(u64),

        pub fn init(options: Options) Self {
            const rnd = Random.init(options.random);
            const fp = fingerprint(rnd);

            return .{
                .rnd = rnd,
                .fingerprint = fp,
                .counter = std.atomic.Value(u64).init(rnd.int(u64, MaxSessionInitCount)),
            };
        }

        /// Generates a cuid2 identifier.
        pub fn next(self: *Self) [length]u8 {

            // u64 values result in max 13 base36 chars
            // 32 = max id length
            // 64 = fingerprint
            var bytes: [13 + 13 + 32 + 64]u8 = undefined;
            var len: usize = 0;

            len += std.fmt.formatIntBuf(&bytes, std.time.microTimestamp(), 36, .lower, .{});

            const salt = self.rnd.base63(32); // TODO: use same size as id length?

            std.mem.copyForwards(u8, bytes[len..], &salt);
            len += salt.len;

            len += std.fmt.formatIntBuf(
                bytes[len..],
                self.counter.fetchAdd(1, .monotonic),
                36,
                .lower,
                .{},
            );

            std.mem.copyForwards(u8, bytes[len..], &self.fingerprint);
            len += self.fingerprint.len;

            var hash: [64]u8 = undefined;
            std.crypto.hash.sha3.Sha3_512.hash(bytes[0..len], &hash, .{});

            return format(hash, self.rnd.aplpha());
        }

        /// Verifies wether the supplied value is a valid `Cuid2(length)`.
        pub fn isValid(id: []const u8) bool {
            if (id.len != length) return false;

            for (id) |c| {
                switch (c) {
                    '0'...'9' => {},
                    'a'...'z' => {},
                    else => return false,
                }
            }

            return true;
        }

        fn format(hash: [64]u8, firstChar: u8) [length]u8 {

            // we need to accomodate the 64 bytes of the hash
            // and we need an extra one as buffer
            const len = 64 / @sizeOf(Limb) + 1;

            var limbs: [len]Limb = undefined;
            var big = Mutable.init(&limbs, 0);

            for (hash) |byte| {
                big.shiftLeft(big.toConst(), 8);
                big.add(big.toConst(), .{ .limbs = &[_]Limb{byte}, .positive = true });
            }

            const base = Const{ .limbs = &[_]usize{36}, .positive = true };

            var buf: [length]u8 = undefined;
            buf[0] = firstChar;
            var offset: u8 = 1;

            var remainderLimbs = [_]usize{0};
            var r = Mutable.init(&remainderLimbs, 0);
            var buffer: [9 + 2]std.math.big.Limb = undefined;

            // we're skipping the first base36 char to avoid histogram bias
            // https://github.com/paralleldrive/cuid2/blob/53e246b0919c8123e492e6b6bbab41fe66f4b462/src/index.js#L32
            big.divFloor(&r, big.toConst(), base, &buffer);

            while (true) {
                big.divFloor(&r, big.toConst(), base, &buffer);

                // the remainder is in range `[0, 36)` so we can just cast the first limb
                buf[offset] = toBase36Char(@intCast(r.limbs[0]));
                offset += 1;

                if (offset == buf.len or big.eqlZero()) break;
            }

            return buf;
        }

        /// Returns a fingerprint based on the current environment.
        fn fingerprint(rnd: Random) [64]u8 {
            var sha = std.crypto.hash.sha3.Sha3_512.init(.{});
            for (std.os.environ) |e| {
                sha.update(std.mem.span(e));
            }
            sha.update(&rnd.base63(32));
            var hash: [64]u8 = undefined;
            sha.final(&hash);
            return hash;
        }

        /// Returns a 0-9 or a-z for
        fn toBase36Char(value: u8) u8 {
            return switch (value) {
                0...9 => value + '0',
                10...35 => value + 'a' - 10,
                else => unreachable,
            };
        }
    };
}

test "Cuid2.next()" {
    var cuid_20 = Cuid2(20).init(.{});

    try testing.expectEqual(20, cuid_20.next().len);

    var cuid_3 = Cuid2(3).init(.{});

    try testing.expectEqual(3, cuid_3.next().len);
}

test "Cuid2.isValid()" {
    var cuid_20 = Cuid2(20).init(.{});

    try testing.expectEqual(true, Cuid2(20).isValid(&cuid_20.next()));
    try testing.expectEqual(false, Cuid2(2).isValid(&cuid_20.next()));
    try testing.expectEqual(true, Cuid2(2).isValid("aa"));
    try testing.expectEqual(false, Cuid2(2).isValid("  "));
    try testing.expectEqual(false, Cuid2(2).isValid("AA"));
}
