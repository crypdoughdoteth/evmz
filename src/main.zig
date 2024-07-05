const std = @import("std");
const opcodes = @import("opcodes.zig");
const Opcode = opcodes.Opcode;
const Gas = @import("Gas.zig");
const Stack = @import("Stack.zig");
const Evm = @import("./Evm.zig");

pub fn main() !void {
    var stack: Stack = .{};
    var gas: Gas = try Gas.new(50000000, 50000);
    var evm: Evm = .{
        .program_counter = 0,
        .stack = &stack,
        .gas = &gas,
        .success = false,
    };

    const ops: []const u8 = &.{0x00};
    try evm.exec(ops);

    std.debug.print("{}", .{evm.success});
}
