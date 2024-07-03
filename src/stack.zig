const std = @import("std");
const Opcode = @import("opcodes.zig").Opcode;
const STACK_SIZE: usize = 1024;
const Stack = @This();
stack: [STACK_SIZE]u256 = [_]u256{0} ** STACK_SIZE,
length: usize = 0,

pub fn get(self: *const Stack, idx: usize) ?u256 {
    if (idx >= self.length) {
        return null;
    }
    return self.stack[idx];
}

pub fn push(self: *Stack, val: u256) StackError!void {
    if (self.length >= STACK_SIZE) {
        return StackError.StackFull;
    }

    self.stack[self.length] = val;
    self.free_slot += 1;
}

pub fn pop(self: *Stack) StackError!u256 {
    if (self.length == 0) {
        return StackError.StackUnderflow;
    }
    self.length -= 1;
    const res = self.stack[self.length];
    self.stack[self.length] = 0;
    return res;
}

// top value on stack
pub fn top(self: *const Stack) ?u256 {
    if (self.length == 0) {
        return null;
    }
    return self.stack[self.length - 1];
}

const StackError = error{
    StackOverflow,
    StackUnderflow,
};
