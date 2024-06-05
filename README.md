# Cuid2

Secure, collision-resistant ids optimized for horizontal scaling and performance. Next generation UUIDs.

Need unique ids in your app? Forget UUIDs and GUIDs which often collide in large apps. Use Cuid2, instead.

This is a port of the JavaScript library [@paralleldrive/cuid2](https://github.com/paralleldrive/cuid2), rewritten in Zig. For more detailed information about Cuid2, please refer to the [original documentation](https://github.com/paralleldrive/cuid2/blob/main/README.md).

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

````zig
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
````

The random function must return a `f64` value in range `[0,1)`.  The default implementation uses `std.rand.DefaultPrng` with a `std.time.microTimestamp()` seed.

## Importing the library

TODO


