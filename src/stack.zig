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

fn top(self: *const Stack) ?u256 {
    if (self.length == 0) {
        return null;
    } else {
        return self.stack.free_slot - 1;
    }
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

fn last(self: *const Stack) ?u256 {
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
                    return;
                },
                //                .return => try retrn(),
                inline else => |op| try @field(Evm, @tagName(op))(self),
            }
        }
    }

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
        _ = evm;
        {}
    }

    fn mulmod(evm: *Evm) !void {
        _ = evm;
        {}
    }

    fn exp(evm: *Evm) !void {
        _ = evm;
        {}
    }

    fn sigextend(evm: *Evm) !void {
        _ = evm;
        {}
    }
};

const OpcodeErrors = error{
    UnknownOpcode,
    StackUnderflow,
};
