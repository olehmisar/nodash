use crate::error::Error;

/// A trait for fallible type conversions.
pub trait TryFrom<T> {
    /// Attempts to convert from type `T` to `Self`.
    ///
    /// # Returns
    /// - `Result::ok(Self)` if the conversion is successful.
    /// - `Result::err(Error)` if the conversion fails (e.g., due to out-of-bounds value).
    fn try_from(input: T) -> Result<Self, Error>;
}

/// Converts a `Field` to `u8`.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field value is too large to fit in a `u8`.
impl TryFrom<Field> for u8 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 8 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u8)
        }
    }
}

/// Converts a `Field` to `bool`.
/// Returns `Ok(false)` for Field 0, `Ok(true)` for Field 1.
/// Returns `Err(Error::ValueOutOfBounds)` for any other Field value.
impl TryFrom<Field> for bool {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input == (0 as Field) {
            Result::ok(false)
        } else if input == (1 as Field) {
            Result::ok(true)
        } else {
            Result::err(Error::ValueOutOfBounds) 
        }
    }
}

/// Converts a `Field` to `u16`.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field value is too large to fit in a `u16`.
impl TryFrom<Field> for u16 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 16 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u16)
        }
    }
}

/// Converts a `Field` to `u32`.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field value is too large to fit in a `u32`.
impl TryFrom<Field> for u32 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 32 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u32)
        }
    }
}

/// Converts a `Field` to `u64`.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field value is too large to fit in a `u64`.
impl TryFrom<Field> for u64 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 64 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u64)
        }
    }
}

/// Converts a `Field` to `u128`.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field value is too large to fit in a `u128`.
impl TryFrom<Field> for u128 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 128 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u128)
        }
    }
}

impl TryFrom<Field> for i8 {
    /// Converts a `Field` to `i8`.
    ///
    /// # Warning
    /// This conversion currently only checks if the magnitude of the Field value (interpreted as positive)
    /// fits within 7 bits (i.e., `0 <= Field_value <= 127`). It does not handle negative numbers
    /// represented by Field values (e.g., `P-1` for `-1`). A more comprehensive signed conversion
    /// from Field is needed for full support.
    ///
    /// Returns `Err(Error::ValueOutOfBounds)` if the Field's positive magnitude is too large.
    fn try_from(input: Field) -> Result<Self, Error> {
        // TODO: Implement full signed conversion from Field, considering negative representations.
        if input.get_max_bit_size() > 7 { // Max positive value for i8 is 2^7 - 1
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i8)
        }
    }
}

/// Converts a `Field` to `i16`. See `TryFrom<Field> for i8` for current limitations on signed conversion.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field's positive magnitude is too large.
impl TryFrom<Field> for i16 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 15 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i16)
        }
    }
}

/// Converts a `Field` to `i32`. See `TryFrom<Field> for i8` for current limitations on signed conversion.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field's positive magnitude is too large.
impl TryFrom<Field> for i32 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 31 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i32)
        }
    }
}

/// Converts a `Field` to `i64`. See `TryFrom<Field> for i8` for current limitations on signed conversion.
/// Returns `Err(Error::ValueOutOfBounds)` if the Field's positive magnitude is too large.
impl TryFrom<Field> for i64 {
    fn try_from(input: Field) -> Result<Self, Error> {
        if input.get_max_bit_size() > 63 {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i64)
        }
    }
}

// Implementations for uN -> uM (down-casting)

/// Converts `u16` to `u8`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `u16` value is greater than `u8::max_value()`.
impl TryFrom<u16> for u8 {
    fn try_from(input: u16) -> Result<Self, Error> {
        if input > (u8::max_value() as u16) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u8)
        }
    }
}

/// Converts `u32` to `u8`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `u32` value is greater than `u8::max_value()`.
impl TryFrom<u32> for u8 {
    fn try_from(input: u32) -> Result<Self, Error> {
        if input > (u8::max_value() as u32) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u8)
        }
    }
}

/// Converts `u32` to `u16`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `u32` value is greater than `u16::max_value()`.
impl TryFrom<u32> for u16 {
    fn try_from(input: u32) -> Result<Self, Error> {
        if input > (u16::max_value() as u32) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u16)
        }
    }
}

/// Converts `u64` to `u32`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `u64` value is greater than `u32::max_value()`.
impl TryFrom<u64> for u32 {
    fn try_from(input: u64) -> Result<Self, Error> {
        if input > (u32::max_value() as u64) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u32)
        }
    }
}

/// Converts `u128` to `u64`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `u128` value is greater than `u64::max_value()`.
impl TryFrom<u128> for u64 {
    fn try_from(input: u128) -> Result<Self, Error> {
        if input > (u64::max_value() as u128) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as u64)
        }
    }
}

// Signed integer down-casting

/// Converts `i16` to `i8`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `i16` value is outside the range of `i8`.
impl TryFrom<i16> for i8 {
    fn try_from(input: i16) -> Result<Self, Error> {
        if input > (i8::max_value() as i16) || input < (i8::min_value() as i16) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i8)
        }
    }
}

/// Converts `i32` to `i16`.
/// Returns `Err(Error::ValueOutOfBounds)` if the input `i32` value is outside the range of `i16`.
impl TryFrom<i32> for i16 {
    fn try_from(input: i32) -> Result<Self, Error> {
        if input > (i16::max_value() as i32) || input < (i16::min_value() as i32) {
            Result::err(Error::ValueOutOfBounds)
        } else {
            Result::ok(input as i16)
        }
    }
}


// Up-casting (always safe, so just direct conversion)
// These could also be implemented if desired for API completeness, always returning Ok.
// Example:
// impl TryFrom<u8> for u16 {
//     fn try_from(input: u8) -> Result<Self, Error> {
//         Result::ok(input as u16)
//     }
// }


mod tests {
    use super::TryFrom;
    use crate::error::Error;

    #[test]
    fn test_try_from_u8_ok() {
        assert(u8::try_from(123).unwrap() == 123);
    }

    #[test]
    fn test_try_from_u128_ok() {
        assert(u128::try_from(123).unwrap() == 123);
         let max_u128_field = (1u128 << 127) as Field; // Create a large field value
        // This line above is problematic. (1u128 << 127) is already a u128.
        // Field::from_u128 is not standard. (u128_val as Field) is how it's done.
        // Let's test with u128::max_value() if possible, or a known large value.
        // Field max value is large, so any u128 can be cast to Field.
        // The test is Field -> u128.
        let field_val_for_max_u128 = u128::max_value() as Field;
        // This might hit field prime order if u128::max_value is too close.
        // Field::max_value() is prime, around 2^254. u128::max_value() is 2^128-1.
        // So, `u128::max_value() as Field` is fine.
        assert(u128::try_from(field_val_for_max_u128).unwrap() == u128::max_value());
    }

    #[test]
    fn test_try_from_u8_fail_too_large() {
        let result = u8::try_from(256);
        assert(result.is_err());
        assert(result.err().unwrap() == Error::ValueOutOfBounds);
    }
    
    #[test]
    fn test_try_from_u8_fail_negative_field_representation() {
        // Field can represent negative numbers modulo P.
        // E.g. -1 mod P is P-1. P-1 usually has many bits.
        // This test checks if a Field value that's "negative" (i.e. large positive representing negative)
        // correctly fails conversion to u8.
        let p_minus_1 = Field::max_value(); // This is a large number
        let result = u8::try_from(p_minus_1);
         assert(result.is_err());
        assert(result.err().unwrap() == Error::ValueOutOfBounds);
    }

    // TODO: Add tests for signed integer conversions (i8, i16, etc.)
    // These would need to consider how negative numbers are represented in Field
    // and what the expected behavior is. For example, should a Field value of (P-1)
    // convert to -1 for signed types if it fits? This depends on Field's nature.
    // The current impls for iN only check positive range via get_max_bit_size.

    #[test]
    fn test_try_from_u16_to_u8() {
        assert(u8::try_from(255u16).unwrap() == 255u8);
        assert(u8::try_from(0u16).unwrap() == 0u8);
        let res = u8::try_from(256u16);
        assert(res.is_err());
        assert(res.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_u32_to_u8() {
        assert(u8::try_from(255u32).unwrap() == 255u8);
        let res = u8::try_from(256u32);
        assert(res.is_err());
        assert(res.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_u32_to_u16() {
        assert(u16::try_from(65535u32).unwrap() == 65535u16);
        let res = u16::try_from(65536u32);
        assert(res.is_err());
        assert(res.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_u64_to_u32() {
        assert(u32::try_from(u32::max_value() as u64).unwrap() == u32::max_value());
        let res = u32::try_from((u32::max_value() as u64) + 1);
        assert(res.is_err());
        assert(res.err().unwrap() == Error::ValueOutOfBounds);
    }
    
    #[test]
    fn test_try_from_u64_field_edges() {
        // Test 0
        assert(u64::try_from(0 as Field).unwrap() == 0u64);
        // Test u64::max_value()
        let max_u64_as_field = u64::max_value() as Field;
        assert(u64::try_from(max_u64_as_field).unwrap() == u64::max_value());
    }

    #[test]
    fn test_try_from_u128_to_u64() {
        assert(u64::try_from(u64::max_value() as u128).unwrap() == u64::max_value());
        let res = u64::try_from((u64::max_value() as u128) + 1);
        assert(res.is_err());
        assert(res.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_i16_to_i8() {
        assert(i8::try_from(127i16).unwrap() == 127i8);
        assert(i8::try_from(-128i16).unwrap() == -128i8);
        assert(i8::try_from(0i16).unwrap() == 0i8);

        let res_overflow_pos = i8::try_from(128i16);
        assert(res_overflow_pos.is_err());
        assert(res_overflow_pos.err().unwrap() == Error::ValueOutOfBounds);
        
        let res_overflow_neg = i8::try_from(-129i16);
        assert(res_overflow_neg.is_err());
        assert(res_overflow_neg.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_i32_to_i16() {
        assert(i16::try_from(32767i32).unwrap() == 32767i16);
        assert(i16::try_from(-32768i32).unwrap() == -32768i16);
        assert(i16::try_from(0i32).unwrap() == 0i16);

        let res_overflow_pos = i16::try_from(32768i32);
        assert(res_overflow_pos.is_err());
        assert(res_overflow_pos.err().unwrap() == Error::ValueOutOfBounds);

        let res_overflow_neg = i16::try_from(-32769i32);
        assert(res_overflow_neg.is_err());
        assert(res_overflow_neg.err().unwrap() == Error::ValueOutOfBounds);
    }

    #[test]
    fn test_try_from_field_to_bool() {
        assert(bool::try_from(0 as Field).unwrap() == false);
        assert(bool::try_from(1 as Field).unwrap() == true);

        let res_two = bool::try_from(2 as Field);
        assert(res_two.is_err());
        assert(res_two.err().unwrap() == Error::ValueOutOfBounds);
        
        let large_field_val = 1234567 as Field;
        let res_large = bool::try_from(large_field_val);
        assert(res_large.is_err());
        assert(res_large.err().unwrap() == Error::ValueOutOfBounds);

        // Test with Field::max_value() which is neither 0 nor 1
        let res_max_field = bool::try_from(Field::max_value());
        assert(res_max_field.is_err());
        assert(res_max_field.err().unwrap() == Error::ValueOutOfBounds);
    }
}
