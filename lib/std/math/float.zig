const std = @import("../std.zig");
const assert = std.debug.assert;
const expect = std.testing.expect;

/// Creates a raw "1.0" mantissa for floating point type T. Used to dedupe f80 logic.
fn mantissaOne(comptime T: type) comptime_int {
    return if (floatMantissaDigits(T) == 64) 1 << 63 else 0;
}

/// Creates floating point type T from an unbiased exponent and raw mantissa.
fn reconstructFloat(comptime T: type, exponent: comptime_int, mantissa: comptime_int) T {
    const TBits = std.meta.Int(.unsigned, @bitSizeOf(T));
    const biased_exponent = @as(TBits, exponent + floatExponentMax(T));
    return @bitCast(T, (biased_exponent << floatMantissaBits(T)) | @as(TBits, mantissa));
}

/// Returns the number of bits in the exponent of floating point type T.
pub fn floatExponentBits(comptime T: type) comptime_int {
    assert(@typeInfo(T) == .Float);

    return switch (@typeInfo(T).Float.bits) {
        16 => 5,
        32 => 8,
        64 => 11,
        80 => 15,
        128 => 15,
        else => @compileError("unknown floating point type " ++ @typeName(T)),
    };
}

/// Returns the number of bits in the mantissa of floating point type T.
pub fn floatMantissaBits(comptime T: type) comptime_int {
    assert(@typeInfo(T) == .Float);

    return switch (@typeInfo(T).Float.bits) {
        16 => 10,
        32 => 23,
        64 => 52,
        80 => 64,
        128 => 112,
        else => @compileError("unknown floating point type " ++ @typeName(T)),
    };
}

/// Returns the number of binary digits in the mantissa of floating point type T.
pub fn floatMantissaDigits(comptime T: type) comptime_int {
    assert(@typeInfo(T) == .Float);

    // standard IEEE floats have an implicit 0.m or 1.m integer part
    // f80 is special and has an explicitly stored bit in the MSB
    // this function corresponds to `MANT_DIG' constants from C
    return switch (@typeInfo(T).Float.bits) {
        16 => 11,
        32 => 24,
        64 => 53,
        80 => 64,
        128 => 113,
        else => @compileError("unknown floating point type " ++ @typeName(T)),
    };
}

/// Returns the minimum exponent that can represent
/// a normalised value in floating point type T.
pub fn floatExponentMin(comptime T: type) comptime_int {
    return -floatExponentMax(T) + 1;
}

/// Returns the maximum exponent that can represent
/// a normalised value in floating point type T.
pub fn floatExponentMax(comptime T: type) comptime_int {
    return (1 << (floatExponentBits(T) - 1)) - 1;
}

/// Returns the smallest subnormal number representable in floating point type T.
pub fn floatTrueMin(comptime T: type) T {
    return reconstructFloat(T, floatExponentMin(T) - 1, 1);
}

/// Returns the smallest normal number representable in floating point type T.
pub fn floatMin(comptime T: type) T {
    return reconstructFloat(T, floatExponentMin(T), mantissaOne(T));
}

/// Returns the largest normal number representable in floating point type T.
pub fn floatMax(comptime T: type) T {
    const all1s_mantissa = (1 << floatMantissaBits(T)) - 1;
    return reconstructFloat(T, floatExponentMax(T), all1s_mantissa);
}

/// Returns the machine epsilon of floating point type T.
pub fn floatEps(comptime T: type) T {
    return reconstructFloat(T, -(floatMantissaDigits(T) - 1), mantissaOne(T));
}

test "std.math.float" {
    inline for ([_]type{ f16, f32, f64, f80, f128, c_longdouble }) |T| {
        // (1 +) for the sign bit, since it is separate from the other bits
        const size = 1 + floatExponentBits(T) + floatMantissaBits(T);
        try expect(@bitSizeOf(T) == size);

        // for machine epsilon, assert expmin <= -prec <= expmax
        try expect(floatExponentMin(T) <= -(floatMantissaDigits(T) - 1));
        try expect(-(floatMantissaDigits(T) - 1) <= floatExponentMax(T));
    }
}
