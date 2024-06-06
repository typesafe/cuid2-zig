const std = @import("std");
const testing = std.testing;

const Limb = std.math.big.Limb;
const Const = std.math.big.int.Const;
const Managed = std.math.big.int.Managed;

const Cuid2 = @import("../cuid2.zig").Cuid2;

pub fn generateHistogram(comptime count: usize) !void {
    var set = try generateIds(count);
    defer set.deinit();

    try printDistributionHistogram(set);
    try printCharacterHistogram(set);
}

fn generateIds(count: usize) !std.AutoHashMap([24]u8, void) {
    var cuid2 = Cuid2(24).init(.{});

    var set = std.AutoHashMap([24]u8, void).init(testing.allocator);

    std.debug.print("\nGenerating {} cuids...\n", .{count});

    for (0..count) |i| {
        const id = cuid2.next();
        try set.put(id, {});

        if (set.count() < i + 1) {
            std.debug.print("\nCollision at {}!", .{i});
            return error.Collision;
        }
    }

    return set;
}

fn printDistributionHistogram(set: std.AutoHashMap([24]u8, void)) !void {
    const count = set.count();

    const numberOfBuckets = 20;
    var bucketCount = try Managed.init(testing.allocator);
    defer bucketCount.deinit();
    try bucketCount.set(numberOfBuckets);

    var radix = try Managed.init(testing.allocator);
    defer radix.deinit();
    try radix.set(36);

    var maxBuckets = try Managed.init(testing.allocator);
    defer maxBuckets.deinit();
    try maxBuckets.set(1);

    // 23 instead of 24, to account for the skewing of the first alpha-only character.
    for (0..23) |_| {
        try maxBuckets.mul(&maxBuckets, &radix);
    }

    std.debug.print("{}\n", .{maxBuckets});
    var rem = try Managed.init(testing.allocator);
    defer rem.deinit();
    try rem.set(0);

    var bucketLength = try Managed.init(testing.allocator);
    defer bucketLength.deinit();
    try bucketLength.set(0);
    try bucketLength.divTrunc(&rem, &maxBuckets, &bucketCount);

    var buckets: [numberOfBuckets]usize = undefined;
    @memset(&buckets, 0);

    var value = try Managed.init(testing.allocator);
    defer value.deinit();

    var it = set.keyIterator();
    while (it.next()) |id| {
        // skip first char, this is always an 'a' -> 'z' character
        // and skews the results
        try toBigInt(id.*[1..], &value, &radix);

        try value.divFloor(&rem, &value, &bucketLength);

        buckets[value.limbs[0]] += 1;
    }

    printBuckets(&buckets, count, 40);
}

fn printCharacterHistogram(set: std.AutoHashMap([24]u8, void)) !void {
    var charBuckets: [36]usize = undefined;
    @memset(&charBuckets, 0);

    var it = set.keyIterator();
    while (it.next()) |id| {
        // skip first char
        for (id[1..]) |c| {
            charBuckets[fromBase36(c)] += 1;
        }
    }

    var minBucket: usize = std.math.maxInt(usize);
    var maxBucket: usize = 0;

    const count = set.count();
    const avgBucketSize = @as(f32, @floatFromInt(23 * count / 36));
    const ratio = @as(f32, @floatFromInt(40)) / (avgBucketSize * 1.1);

    for (charBuckets) |b| {
        minBucket = @min(minBucket, b);
        maxBucket = @max(maxBucket, b);
    }

    for (0..36) |i| {
        const c = toBase36Char(@intCast(i));

        printBucket(@intFromFloat(@as(f32, @floatFromInt(charBuckets[i])) * ratio), 40);
        std.debug.print(" {c}: {}\n", .{ @as(u8, @intCast(c)), charBuckets[i] });
    }
    std.debug.print("min {} ({d:.2}%) max: {} ({d:.2}%)\n", .{
        minBucket,
        (avgBucketSize - @as(f32, @floatFromInt(minBucket))) * 100 / avgBucketSize,
        maxBucket,
        (@as(f32, @floatFromInt(maxBucket)) - avgBucketSize) * 100 / avgBucketSize,
    });
}

fn toBase36Char(value: u8) u8 {
    return switch (value) {
        0...9 => value + '0',
        10...35 => value + 'a' - 10,
        else => unreachable,
    };
}

fn printBucket(len: usize, total: usize) void {
    for (0..total) |i| {
        if (i <= len) {
            std.debug.print("█", .{});
        } else {
            std.debug.print("░", .{});
        }
    }
}

fn printBuckets(buckets: []const usize, count: usize, width: usize) void {
    var minBucket: usize = std.math.maxInt(usize);
    var maxBucket: usize = 0;

    const avgBucketSize = @as(f32, @floatFromInt(count)) / @as(f32, @floatFromInt(buckets.len));
    const ratio = @as(f32, @floatFromInt(width)) / (avgBucketSize * 1.1); // 10% margin (should be only 5%)

    for (buckets) |bucket| {
        minBucket = @min(minBucket, bucket);
        maxBucket = @max(maxBucket, bucket);
        const len = @as(usize, @intFromFloat(ratio * @as(f32, @floatFromInt(bucket))));

        printBucket(len, width);

        std.debug.print(" {}\n", .{bucket});
    }

    std.debug.print("min {} ({d:.2}%) max: {} ({d:.2}%)\n", .{
        minBucket,
        (avgBucketSize - @as(f32, @floatFromInt(minBucket))) * 100 / avgBucketSize,
        maxBucket,
        (@as(f32, @floatFromInt(maxBucket)) - avgBucketSize) * 100 / avgBucketSize,
    });
}

fn toBigInt(id: []const u8, value: *Managed, radix: *Managed) !void {
    try value.set(0);
    for (id) |byte| {
        try value.mul(value, radix);
        try value.addScalar(value, fromBase36(byte));
    }
}

fn fromBase36(value: u8) u8 {
    return switch (value) {
        '0'...'9' => value - '0',
        'a'...'z' => value - 'a' + 10,
        else => unreachable,
    };
}
