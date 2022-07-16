const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Limb = std.math.big.Limb;
const Const = std.math.big.int.Const;
const Managed = std.math.big.int.Managed;
const Mutable = std.math.big.int.Mutable;
const calcMulLimbsBufferLen = std.math.big.int.calcMulLimbsBufferLen;
const maxInt = std.math.maxInt;

pub fn mul(rma: *Managed, a: Const, b: Const) Allocator.Error!void {
    var m: Mutable = undefined;
    var a2 = a;
    var b2 = b;
    const is_a_alias = a.limbs.ptr == rma.limbs.ptr;
    const is_b_alias = b.limbs.ptr == rma.limbs.ptr;
    if (is_a_alias or is_b_alias) {
        try rma.ensureMulCapacity(a, b);
        var alias_count: usize = 0;
        if (is_a_alias) {
            a2.limbs.ptr = rma.limbs.ptr;
            alias_count += 1;
        }
        if (is_b_alias) {
            b2.limbs.ptr = rma.limbs.ptr;
            alias_count += 1;
        }
        const limb_count = calcMulLimbsBufferLen(a2.limbs.len, b2.limbs.len, alias_count);
        const limbs_buffer = try rma.allocator.alloc(Limb, limb_count);
        defer rma.allocator.free(limbs_buffer);
        m = rma.toMutable();
        m.mul(a2, b2, limbs_buffer, rma.allocator);
    } else {
        m = rma.toMutable();
        m.mulNoAlias(a2, b2, rma.allocator);
    }
    rma.setMetadata(m.positive, m.len);
}

/// r = a * a
pub fn sqr(rma: *Managed, a: Const) Allocator.Error!void {
    const needed_limbs = 2 * a.limbs.len + 1;

    if (rma.limbs.ptr == a.limbs.ptr) {
        var m = try Managed.initCapacity(rma.allocator, needed_limbs);
        errdefer m.deinit();
        var m_mut = m.toMutable();
        m_mut.sqrNoAlias(a, rma.allocator);
        m.setMetadata(m_mut.positive, m_mut.len);

        rma.deinit();
        rma.swap(&m);
    } else {
        try rma.ensureCapacity(needed_limbs);
        var rma_mut = rma.toMutable();
        rma_mut.sqrNoAlias(a, rma.allocator);
        rma.setMetadata(rma_mut.positive, rma_mut.len);
    }
}

pub fn add(r: *Managed, a: Const, b: Const) Allocator.Error!void {
    var a2 = a;
    var b2 = b;
    const is_a_alias = a.limbs.ptr == r.limbs.ptr;
    const is_b_alias = b.limbs.ptr == r.limbs.ptr;
    if (is_a_alias or is_b_alias) {
        try r.ensureAddCapacity(a, b);
        if (is_a_alias) a2.limbs.ptr = r.limbs.ptr;
        if (is_b_alias) b2.limbs.ptr = r.limbs.ptr;
    }
    var m = r.toMutable();
    m.add(a2, b2);
    r.setMetadata(m.positive, m.len);
}

pub fn sub(r: *Managed, a: Const, b: Const) Allocator.Error!void {
    var a2 = a;
    var b2 = b;
    const is_a_alias = a.limbs.ptr == r.limbs.ptr;
    const is_b_alias = b.limbs.ptr == r.limbs.ptr;
    if (is_a_alias or is_b_alias) {
        try r.ensureAddCapacity(a, b);
        if (is_a_alias) a2.limbs.ptr = r.limbs.ptr;
        if (is_b_alias) b2.limbs.ptr = r.limbs.ptr;
    }
    var m = r.toMutable();
    m.sub(a2, b2);
    r.setMetadata(m.positive, m.len);
}

test "big.int mul multi-multi no alias" {
    var a = try Managed.initSet(testing.allocator, 0);
    defer a.deinit();
    var b = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer b.deinit();
    var c = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer c.deinit();

    try mul(&a, b.toConst(), c.toConst());

    var want = try Managed.initSet(testing.allocator, 4 * maxInt(Limb) * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 4), a.limbs.len);
    }
}

test "big.int mul multi-multi alias r with a and b" {
    var a = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer a.deinit();

    try mul(&a, a.toConst(), a.toConst());

    var want = try Managed.initSet(testing.allocator, 4 * maxInt(Limb) * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 5), a.limbs.len);
    }
}

test "big.int sqr multi-multi no alias" {
    var a = try Managed.initSet(testing.allocator, 0);
    defer a.deinit();
    var b = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer b.deinit();

    try sqr(&a, b.toConst());

    var want = try Managed.initSet(testing.allocator, 4 * maxInt(Limb) * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 5), a.limbs.len);
    }
}

test "big.int sqr multi-multi alias r with a" {
    var a = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer a.deinit();

    try sqr(&a, a.toConst());

    var want = try Managed.initSet(testing.allocator, 4 * maxInt(Limb) * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 5), a.limbs.len);
    }
}

test "big.int add multi-multi alias r with a and b" {
    var a = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer a.deinit();

    try add(&a, a.toConst(), a.toConst());

    var want = try Managed.initSet(testing.allocator, 4 * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 4), a.limbs.len);
    }
}

test "big.int sub multi-multi alias r with a and b" {
    var a = try Managed.initSet(testing.allocator, 0);
    defer a.deinit();
    var b = try Managed.initSet(testing.allocator, 2 * maxInt(Limb));
    defer b.deinit();

    try sub(&a, a.toConst(), b.toConst());

    var want = try Managed.initSet(testing.allocator, -2 * maxInt(Limb));
    defer want.deinit();

    try testing.expect(a.eq(want));

    if (@typeInfo(Limb).Int.bits == 64) {
        try testing.expectEqual(@as(usize, 4), a.limbs.len);
    }
}
