var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
const builtin = @import("builtin");
const std = @import("std");
const game = @import("game.zig");

pub fn main() !void {
  const allocator, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };

    defer if (is_debug) {
        switch (debug_allocator.deinit()) {
            .leak => std.debug.print("You leaked memory dum dum\n", .{}),
            .ok => std.debug.print("No memory leaks. For now...\n", .{}),
        }
    };

    try game.Game.run(allocator);
}
