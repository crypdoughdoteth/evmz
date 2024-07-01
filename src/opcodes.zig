const Stack = @import("./Stack.zig");
const std = @import("std");

pub const Opcode = enum(u8) {
    stop = 0x00,
    add = 0x01,
    mul = 0x02,
    sub = 0x03,
    div = 0x04,
    sdiv = 0x05,
    mod = 0x06,
    smod = 0x07,
    addmod = 0x08,
    mulmod = 0x09,
    exp = 0x0A,
    signextend = 0x0B,
};
