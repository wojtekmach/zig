export fn entry() void {
    const ints = [_]u8{ 1, 2 };
    inline for (ints) |_| {
        bad() catch continue;
    }
}
fn bad() !void {
    return error.Bad;
}

// comptime continue inside runtime catch
//
// tmp.zig:4:21: error: comptime control flow inside runtime block
// tmp.zig:4:15: note: runtime block created here
