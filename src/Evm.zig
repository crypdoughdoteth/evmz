const Stack = @import("Stack.zig");
const Gas = @import("Gas.zig");
const opcodes = @import("opcodes.zig");
const Opcode = opcodes.Opcode;
const Evm = @This();
const std = @import("std");

// limits must be imposed by constraining `starting_gas` field of Gas.
// This is intentional. Starting gas may never exceed a given gas limit anyway.

program_counter: u32,
stack: *Stack,
gas: *Gas,
success: bool,
pub fn exec(self: *Evm, code: []const u8) !void {
    while (true) : (self.program_counter += 1) {
        const opcode: Opcode = @enumFromInt(code[self.program_counter]);

        switch (opcode) {
            .stop => {
                self.success = true;
                break;
            },
            //                .return => try retrn(),
            inline else => |op| try @field(Evm, @tagName(op))(self),
        }
    }
}

// ARITHMETIC OPS: 0x00 - 0x0B
fn add(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return error.StackUnderflow;

    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();
    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    evm.stack.stack[free_ptr - 1] = one +% two;
}

fn mul(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();
    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    evm.stack.stack[free_ptr - 1] = one *% two;
}

fn sub(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();
    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    evm.stack.stack[free_ptr - 1] = one -% two;
}

fn div(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();
    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (two == 0) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = one / two;
    }
}

fn sdiv(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (two == 0) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = @bitCast(@divTrunc(@as(i256, @bitCast(one)), @as(i256, @bitCast(two))));
    }
}

fn mod(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (two == 0) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = one % two;
    }
}

fn smod(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (two == 0) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = @bitCast(@rem(@as(i256, @bitCast(one)), @as(i256, @bitCast(two))));
    }
}

fn addmod(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 2) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(8);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    const three = evm.stack.stack[free_ptr - 3];

    _ = try evm.stack.pop();
    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by two
    // stack shrinks by one
    // bottom value overwritten
    if (three == 0) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = (one + two) % three;
    }
}

fn mulmod(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 2) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(8);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];
    const three = evm.stack.stack[free_ptr - 3];

    _ = try evm.stack.pop();
    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by two
    // stack shrinks by one
    // bottom value overwritten
    evm.stack.stack[free_ptr - 1] = (one * two) % three;
}

fn exp(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    // is there a better way !?
    // there has to be ... right?
    // this is accurate as far as the spec goes, but...
    if (two <= std.math.maxInt(u8)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u8)));
    } else if (two <= std.math.maxInt(u16)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u16)));
    } else if (two <= std.math.maxInt(u24)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u24)));
    } else if (two <= std.math.maxInt(u32)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u32)));
    } else if (two <= std.math.maxInt(u40)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u40)));
    } else if (two <= std.math.maxInt(u48)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u48)));
    } else if (two <= std.math.maxInt(u56)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u56)));
    } else if (two <= std.math.maxInt(u64)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u64)));
    } else if (two <= std.math.maxInt(u72)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u72)));
    } else if (two <= std.math.maxInt(u80)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u80)));
    } else if (two <= std.math.maxInt(u88)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u88)));
    } else if (two <= std.math.maxInt(u96)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u96)));
    } else if (two <= std.math.maxInt(u104)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u104)));
    } else if (two <= std.math.maxInt(u112)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u112)));
    } else if (two <= std.math.maxInt(u120)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u120)));
    } else if (two <= std.math.maxInt(u128)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u128)));
    } else if (two <= std.math.maxInt(u136)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u136)));
    } else if (two <= std.math.maxInt(u144)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u144)));
    } else if (two <= std.math.maxInt(u152)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u152)));
    } else if (two <= std.math.maxInt(u160)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u160)));
    } else if (two <= std.math.maxInt(u168)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u168)));
    } else if (two <= std.math.maxInt(u176)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u176)));
    } else if (two <= std.math.maxInt(u184)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u184)));
    } else if (two <= std.math.maxInt(u192)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u192)));
    } else if (two <= std.math.maxInt(u200)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u200)));
    } else if (two <= std.math.maxInt(u208)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u208)));
    } else if (two <= std.math.maxInt(u216)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u216)));
    } else if (two <= std.math.maxInt(u224)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u224)));
    } else if (two <= std.math.maxInt(u232)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u232)));
    } else if (two <= std.math.maxInt(u240)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u240)));
    } else if (two <= std.math.maxInt(u248)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u248)));
    } else if (two <= std.math.maxInt(u256)) {
        try evm.gas.consumeGas(10 + (50 * @sizeOf(u256)));
    }

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    evm.stack.stack[free_ptr - 1] = std.math.pow(u256, one, two);
}

// Adapted from py-evm https://github.com/ethereum/py-evm/blob/d8df507e42c885ddeca2b64bbb8f10705f075d3e/eth/vm/logic/arithmetic.py#L169
fn signextend(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(5);

    const bits = evm.stack.stack[free_ptr - 1];
    const value = evm.stack.stack[free_ptr - 2];
    _ = try evm.stack.pop();
    var result: u256 = 0;
    if (bits <= 31) {
        const testbit: u8 = @truncate(bits * 8 + 7);
        const sign_bit: u256 = @as(u256, 1) << testbit;
        if ((value & sign_bit) != 0) {
            result = value | (std.math.maxInt(u256) - sign_bit);
        } else {
            result = value & (sign_bit - 1);
        }
    } else {
        result = value;
    }
    evm.stack.stack[free_ptr - 1] = result;
}

// COMPARISON OPS: 0x10 - 0x1D

fn lt(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    if (one < two) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn gt(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    if (one > two) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn slt(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (@bitCast(@as(i256, @bitCast(one)) < @as(i256, @bitCast(two)))) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn sgt(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (@bitCast(@as(i256, @bitCast(one)) > @as(i256, @bitCast(two)))) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn eq(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten
    if (one == two) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn iszero(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr == 0) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];

    if (one == 0) {
        evm.stack.stack[free_ptr - 1] = 1;
    } else {
        evm.stack.stack[free_ptr - 1] = 0;
    }
}

fn _and(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    evm.stack.stack[free_ptr - 1] = one & two;
}

fn _or(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    evm.stack.stack[free_ptr - 1] = one | two;
}

fn xor(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];
    const two = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    evm.stack.stack[free_ptr - 1] = one ^ two;
}

fn not(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const one = evm.stack.stack[free_ptr - 1];

    evm.stack.stack[free_ptr - 1] = ~one;
}

fn byte(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const pos = evm.stack.stack[free_ptr - 1];
    const val = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    if (pos >= 32) {
        evm.stack.stack[free_ptr - 1] = 0;
    } else {
        evm.stack.stack[free_ptr - 1] = (val / std.math.pow(u256, 256, 31 - pos)) % 256;
    }
}

fn shl(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const len = evm.stack.stack[free_ptr - 1];
    const val = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    evm.stack.stack[free_ptr - 1] = (val << @truncate(len)) & std.math.maxInt(u256);
}
fn shr(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const len = evm.stack.stack[free_ptr - 1];
    const val = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    // this is correct because pop will bump the free slot back by one
    // stack shrinks by one
    // bottom value overwritten

    evm.stack.stack[free_ptr - 1] = (val >> @truncate(len)) & std.math.maxInt(u256);
}

fn sar(evm: *Evm) !void {
    const free_ptr = evm.stack.length;
    if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;
    try evm.gas.consumeGas(3);

    const shift = evm.stack.stack[free_ptr - 1];
    const val = evm.stack.stack[free_ptr - 2];

    _ = try evm.stack.pop();

    evm.stack.stack[free_ptr - 1] = @as(u256, @bitCast(@as(i256, @bitCast(shift)) >> @truncate(val))) & std.math.maxInt(u256);
}

// Crypto: 0x20
// Keccak256

const OpcodeErrors = error{
    UnknownOpcode,
    StackUnderflow,
};
