const std = @import("std");
const START_SCANLINE = 112;
const FAR: f64 = 255;
const NEAR: f64 = 20;

fn lerp(v0: f64, v1: f64, t: f64) f64 {
    return v0 + (t * (v1 - v0));
}
pub fn main() void {}
