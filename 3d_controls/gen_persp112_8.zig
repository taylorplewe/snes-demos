const std = @import("std");
const FILEPATH = "bin/persp112_8.bin";
const START_SCANLINE = 112;
const NUM_SNES_SCANLINES = 224;
const FAR_DEFAULT: f64 = 255;
const NEAR_DEFAULT: f64 = 20;

fn printErrorAndExit(comptime msg: []const u8, args: anytype) void {
    const stderr_writer = std.io.getStdErr().writer();
    stderr_writer.print("\x1B[31mERROR\x1B[0m " ++ msg ++ "\n", args) catch unreachable;
    std.process.exit(1);
}
fn printNote(comptime msg: []const u8, args: anytype) !void {
    const stdout_writer = std.io.getStdOut().writer();
    try stdout_writer.print("\x1B[33mNOTE\x1B[0m " ++ msg ++ "\n", args);
}
fn lerp(v0: f64, v1: f64, t: f64) f64 {
    return v0 + (t * (v1 - v0));
}
fn scale(far: f64, near: f64, s: f64) f64 {
    return 1 / lerp(1 / far, 1 / near, s);
}

pub fn main() !void {
    // get args
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const args = try std.process.argsAlloc(arena.allocator());
    var far = FAR_DEFAULT;
    var near = NEAR_DEFAULT;
    if (args.len == 1) {
        try printNote("no FAR or NEAR numbers provided; using {d} and {d}.", .{ far, near });
    }
    if (args.len > 1) {
        far = std.fmt.parseFloat(f64, args[1]) catch {
            printErrorAndExit("provided FAR argument must be a number.", .{});
            unreachable;
        };
        if (far >= 256) {
            printErrorAndExit("FAR must be < 256", .{});
            unreachable;
        }
    }
    if (args.len > 2) {
        near = std.fmt.parseFloat(f64, args[2]) catch {
            printErrorAndExit("provided NEAR argument must be a number.", .{});
            unreachable;
        };
        if (near >= 256) {
            printErrorAndExit("NEAR must be < 256", .{});
            unreachable;
        }
    }

    // open output file
    const f = try std.fs.cwd().createFile(FILEPATH, .{});
    defer f.close();
    const writer = f.writer();

    // write to file
    for (START_SCANLINE..NUM_SNES_SCANLINES) |s| {
        const s_fl: f64 = @floatFromInt(s);
        const s_stretched: f64 = (s_fl - START_SCANLINE) * 2;
        const s_normalized: f64 = s_stretched / NUM_SNES_SCANLINES;
        const val = scale(far, near, s_normalized);
        const val_int: u16 = @intFromFloat(val);
        try writer.writeByte(@intCast(val_int & 0xff));
        std.debug.print("{d} {d}\n", .{ s, val_int });
    }
}
