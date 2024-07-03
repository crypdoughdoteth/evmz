const std = @import("std");
const opcodes = @import("opcodes.zig");
const Opcode = opcodes.Opcode;
const Stack = @import("Stack.zig");
const Evm = @import("./Evm.zig");

pub fn main() !void {
    var stack: Stack = .{};
    var evm: Evm = .{
        .program_counter = 0,
        .stack = &stack,
        .success = false,
    };

    const ops: []const u8 = &.{0x00};
    try evm.exec(ops);

    std.debug.print("{}", .{true});
}
