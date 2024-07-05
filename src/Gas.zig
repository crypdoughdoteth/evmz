const Gas = @This();
const std = @import("std");

starting_gas: u64,
gas_refunded: u64 = 0,
gas_remaining: u64 = 0,
limit: u64,

pub fn new(limit: u64, start: u64) !Gas {
    if (limit < start) {
        return error.GasLimitExceeded;
    }

    return .{
        .limit = limit,
        .starting_gas = start,
    };
}

pub fn consumeGas(gas: *Gas, amount: u64) !void {
    if (gas.gas_remaining < amount) {
        // issue refund
        return error.OutOfGas;
    }

    gas.gas_remaining -= amount;
    return;
}
pub fn returnGas(gas: *Gas, amount: u64) u256 {
    if (gas.starting_gas - gas.gas_remaining >= std.math.maxInt(u64) - amount) {
        return false;
    }
    gas.gas_remaining += amount;
    return;
}
pub fn refundGas(gas: *Gas, amount: u64) !void {
    if (gas.starting_gas - gas.gas_remaining >= std.math.maxInt(u64) - amount) {
        return false;
    }
    gas.gas_remaining += amount;
    return;
}

// EIP-150
// ported from revm
pub fn remaining_63_of_64_parts(gas: *Gas) u64 {
    return gas.gas_remaining - gas.gas_remaining / 64;
}

// additional notes on Gas in the EVM
//
// Gas refunds are issued only at the end of transactions.This is done
// to prevent spam and abuse. Transaction must be successful in order to be claimed.

const GasError = error{
    OutOfGas,
    GasLimitExceeded,
};
