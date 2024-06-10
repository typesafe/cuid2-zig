# Cuid2

Secure, collision-resistant ids optimized for horizontal scaling and performance. Next generation UUIDs.

Need unique ids in your app? Forget UUIDs and GUIDs which often collide in large apps. Use Cuid2, instead.

This is a port of the JavaScript library [@paralleldrive/cuid2](https://github.com/paralleldrive/cuid2), rewritten in Zig. For more detailed information about Cuid2, please refer to the [original documentation](https://github.com/paralleldrive/cuid2/blob/main/README.md).

## Installation

Add the `cuid2` dependency by running:

```bash
> zig fetch --save https://github.com/typesafe/cuid2-zig/archive/refs/tags/v0.0.1-beta.tar.gz
```

or adding this to your `build.zig.zon` dependencies directly:

```zig
.cuid2 = .{
    .url = "https://github.com/typesafe/cuid2-zig/archive/refs/tags/v0.0.1-beta.tar.gz",
    .hash = "1220f30bd9592e230ebd976590b7d8130c613801291c781d20b4ace6d26031a990d4",
},
```

Then, add the module to your application in `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {

    // ...

    const cuid2 = b.dependency("cuid2", .{});
    exe.root_module.addImport("cuid2", cuid2.module("cuid2"));

    // ...

}
```

## Usage

`cuid2-zig` requires no memory allocations and is very simple to use. Simply specify the identifier length (a `comptime` value in range `[2,32]`),
initialize it and generate ids:

```zig
const length = 24; // comptime

var generator = Cuid2(length).init(.{});

// `next` returns a fixed-size array of 24 base36 bytes
const id = generator.next();
```

You can also specify a custom random function in the `init` options:

```zig
const std = @import("std");

pub const cuid2 = @import("cuid2");

pub fn main() !void {
    var generator = cuid2.Cuid2(24).init(.{ .random = customRandom });

    std.debug.print("generated id '{s}'\n", .{generator.next()});
}

fn customRandom() f64 {
    // or any other implementation, `std.rand.DefaultCsprng`, ...
    return std.crypto.random.float(f64);
}
```

The random function must return a `f64` value in range `[0,1)`. The default implementation uses `std.rand.DefaultPrng` with a `std.time.microTimestamp()` seed.


## Test Results

Running the histogram test will generate 100k `Cuid2(24)` identifiers, check for collisions and output the following histograms.

An even distribution of the actual value of the ids:

```
█████████████████████████████████████░░░ 5022
█████████████████████████████████████░░░ 5004
█████████████████████████████████████░░░ 5014
█████████████████████████████████████░░░ 5068
█████████████████████████████████████░░░ 4982
████████████████████████████████████░░░░ 4905
█████████████████████████████████████░░░ 4970
█████████████████████████████████████░░░ 5064
█████████████████████████████████████░░░ 4997
████████████████████████████████████░░░░ 4854
█████████████████████████████████████░░░ 5014
█████████████████████████████████████░░░ 5071
██████████████████████████████████████░░ 5104
█████████████████████████████████████░░░ 5023
█████████████████████████████████████░░░ 4951
█████████████████████████████████████░░░ 4999
█████████████████████████████████████░░░ 4988
█████████████████████████████████████░░░ 5025
████████████████████████████████████░░░░ 4882
█████████████████████████████████████░░░ 5063
min 4854 (2.92%) max: 5104 (2.08%)
```

An even distribution of the base36 charaters:

```
█████████████████████████████████████░░░ 0: 63935
█████████████████████████████████████░░░ 1: 63459
█████████████████████████████████████░░░ 2: 63798
█████████████████████████████████████░░░ 3: 64271
█████████████████████████████████████░░░ 4: 64251
█████████████████████████████████████░░░ 5: 64323
█████████████████████████████████████░░░ 6: 63661
█████████████████████████████████████░░░ 7: 64111
█████████████████████████████████████░░░ 8: 63795
█████████████████████████████████████░░░ 9: 64155
█████████████████████████████████████░░░ a: 63895
█████████████████████████████████████░░░ b: 63837
█████████████████████████████████████░░░ c: 63472
█████████████████████████████████████░░░ d: 63812
█████████████████████████████████████░░░ e: 63686
█████████████████████████████████████░░░ f: 63340
█████████████████████████████████████░░░ g: 63823
█████████████████████████████████████░░░ h: 63913
█████████████████████████████████████░░░ i: 64122
█████████████████████████████████████░░░ j: 63838
█████████████████████████████████████░░░ k: 64381
█████████████████████████████████████░░░ l: 64116
█████████████████████████████████████░░░ m: 63973
█████████████████████████████████████░░░ n: 63820
█████████████████████████████████████░░░ o: 63887
█████████████████████████████████████░░░ p: 63825
█████████████████████████████████████░░░ q: 63731
█████████████████████████████████████░░░ r: 63533
█████████████████████████████████████░░░ s: 63831
█████████████████████████████████████░░░ t: 64405
█████████████████████████████████████░░░ u: 64109
█████████████████████████████████████░░░ v: 63586
█████████████████████████████████████░░░ w: 63622
█████████████████████████████████████░░░ x: 63615
█████████████████████████████████████░░░ y: 63787
█████████████████████████████████████░░░ z: 64282
min 63340 (0.86%) max: 64405 (0.81%)
```
