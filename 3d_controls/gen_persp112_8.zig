const std = @import("std");
const START_SCANLINE = 112;
const FAR: f64 = 255;
const NEAR: f64 = 20;

fn lerp(v0: f64, v1: f64, t: f64) f64 {
    return v0 + (t * (v1 - v0));
}
fn scale(s: f64) f64 {
    return 1 / lerp(1 / FAR, 1 / NEAR, s);
}

pub fn main() !void {
    const f = try std.fs.cwd().createFile("bin/persp112_8_zig.bin", "w");
    for (START_SCANLINE..224) |s| {
        const s_stretched = (s - START_SCANLINE) * 2;
        const s_normalized = s_stretched / 224;
        const val = scale(@as(f64, s_normalized));
        const val_int: u16 = @intCast(val);
        std.debug.print("{d} {d}\n", .{val_int});
        try f.write(val_int);
    }
}
