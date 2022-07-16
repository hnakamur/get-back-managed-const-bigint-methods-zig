Get back std.math.big.int.Managed methods with Const arguemnts in Zig
=====================================================================

Arguments of methods of std.math.big.int.Managed were changed from `Const` to `*const Managed`
in [std.math.big.int: breaking API changes to prevent UAF by andrewrk · Pull Request #11964 · ziglang/zig](https://github.com/ziglang/zig/pull/11964).

It becomes inconvinient because we need to create `Managed` instances for actually constant values.

In old signatures like `pub fn add(r: *Managed, a: Const, b: Const) Allocator.Error!void`,
we can use a Const value for `1` in calculation `n = n + 1`, for example.

```zig
pub const one = Const{ .limbs = &[_]Limb{1}, .positive = true };

...(snip)...

// in some functions
var n = Managed.initSet(allocator, 0);
try n.add(n.toConst(), one);
```

In the current signature like `pub fn add(r: *Managed, a: *const Managed, b: *const Managed) Allocator.Error!void`,
we need to create a Managed for `1` like below and it needs heap allocations which were unnecessary before.

```zig
pub const one = Const{ .limbs = &[_]Limb{1}, .positive = true };

...(snip)...

// in some functions
var one_m = try one.toManaged(allocator);
defer one_m.deinit();
var n = Managed.initSet(allocator, 0);
try n.add(n.toConst(), one);
```

So I wrote functions with old signatures which handles argument aliases properly.

* `pub fn mul(rma: *Managed, a: Const, b: Const) Allocator.Error!void`
* `pub fn sqr(rma: *Managed, a: Const) Allocator.Error!void`
* `pub fn add(r: *Managed, a: Const, b: Const) Allocator.Error!void`
* `pub fn sub(r: *Managed, a: Const, b: Const) Allocator.Error!void`

I confirmed tests passed.

```
$ zig test src/main.zig
All 6 tests passed.
$ zig version
0.10.0-dev.3007+6ba2fb3db
```
