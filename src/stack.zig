const std = @import("std");
const Opcode = @import("opcodes.zig").Opcode;
const STACK_SIZE: usize = 1024;
const Stack = @This();
stack: [STACK_SIZE]u256 = [_]u256{0} ** STACK_SIZE,
length: usize = 0,

fn get(self: *const Stack, idx: usize) ?u256 {
    if (idx >= self.length) {
        return null;
    }
    return self.stack[idx];
}

fn push(self: *Stack, val: u256) StackError!void {
    if (self.length >= STACK_SIZE) {
        return StackError.StackFull;
    }

    self.stack[self.length] = val;
    self.free_slot += 1;
}

fn pop(self: *Stack) StackError!u256 {
    if (self.length == 0) {
        return StackError.StackUnderflow;
    }
    self.length -= 1;
    const res = self.stack[self.length];
    self.stack[self.length] = 0;
    return res;
}

// top value on stack
fn top(self: *const Stack) ?u256 {
    if (self.length == 0) {
        return null;
    }
    return self.stack[self.length - 1];
}

const StackError = error{
    StackOverflow,
    StackUnderflow,
};

pub const Evm = struct {
    program_counter: u32,
    stack: *Stack,
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

        const one = evm.stack.stack[free_ptr - 1];

        // this is correct because pop will bump the free slot back by one
        // stack shrinks by one
        // bottom value overwritten
        if (one == 0) {
            evm.stack.stack[free_ptr - 1] = 1;
        } else {
            evm.stack.stack[free_ptr - 1] = 0;
        }
    }

    fn _and(evm: *Evm) !void {
        const free_ptr = evm.stack.length;
        if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;

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

        const one = evm.stack.stack[free_ptr - 1];

        // this is correct because pop will bump the free slot back by one
        // stack shrinks by one
        // bottom value overwritten

        evm.stack.stack[free_ptr - 1] = ~one;
    }

    fn byte(evm: *Evm) !void {
        const free_ptr = evm.stack.length;
        if (free_ptr <= 1) return OpcodeErrors.StackUnderflow;

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

        const len = evm.stack.stack[free_ptr - 1];
        const val = evm.stack.stack[free_ptr - 2];

        _ = try evm.stack.pop();

        evm.stack.stack[free_ptr - 1] = @as(u256, @bitCast(@as(i256, @bitCast(len)) >> @truncate(val))) & std.math.maxInt(u256);
    }

    // Crypto: 0x20
    // Keccak256
};

const OpcodeErrors = error{
    UnknownOpcode,
    StackUnderflow,
};
