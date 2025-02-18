export fn entry() bool {
    var x: u0 = 0;
    const p = @ptrCast(?*u0, &x);
    return p == null;
}

// @ptrCast a 0 bit type to a non- 0 bit type
//
// tmp.zig:3:15: error: '*u0' and '?*u0' do not have the same in-memory representation
// tmp.zig:3:31: note: '*u0' has no in-memory bits
// tmp.zig:3:24: note: '?*u0' has in-memory bits
