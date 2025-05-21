pub(crate) mod sqrt;
pub(crate) mod numeric;

use numeric::Numeric;
use std::{cmp::Eq, ops::{Add, Div, Rem}};

pub fn clamp<T>(x: T, min: T, max: T) -> T
where
    T: Ord,
{
    if (x < min) {
        min
    } else if (x > max) {
        max
    } else {
        x
    }
}

/// Calculates `a / b` and rounds the result up to the nearest integer.
///
/// # Arguments
/// * `a` - The numerator.
/// * `b` - The denominator.
///
/// # Returns
/// - `Option::some(T)` containing the ceiling division result if `b` is not zero.
/// - `Option::none()` if `b` is zero, to prevent division by zero.
///
/// # Type Constraints
/// `T` must implement `Add`, `Div`, `Rem`, `Eq` for arithmetic operations and equality checks,
/// and `Numeric` (from this crate) to provide `zero()` and `one()` values.
pub fn try_div_ceil<T>(a: T, b: T) -> Option<T>
where
    T: Add + Div + Rem + Eq + Numeric,
{
    // Precondition: Denominator `b` cannot be zero.
    if b == T::zero() {
        return Option::none();
    }
    let q = a / b;
    if (a % b == T::zero()) { // If `a` is perfectly divisible by `b`.
        Option::some(q)
    } else { // Otherwise, add one to the truncated quotient to achieve ceiling.
        Option::some(q + T::one())
    }
}

mod tests {
    use crate::math::{clamp, try_div_ceil}; // Renamed div_ceil to try_div_ceil

    #[test]
    fn test_clamp() {
        // u64 tests
        assert(clamp(1u64, 2u64, 5u64) == 2u64); // x < min
        assert(clamp(6u64, 2u64, 5u64) == 5u64); // x > max
        assert(clamp(3u64, 2u64, 5u64) == 3u64); // min < x < max
        assert(clamp(2u64, 2u64, 5u64) == 2u64); // x == min
        assert(clamp(5u64, 2u64, 5u64) == 5u64); // x == max
        assert(clamp(5u64, 5u64, 5u64) == 5u64); // x == min == max

        // Field tests
        assert(clamp(1 as Field, 2 as Field, 5 as Field) == (2 as Field));
        assert(clamp(6 as Field, 2 as Field, 5 as Field) == (5 as Field));
        assert(clamp(3 as Field, 2 as Field, 5 as Field) == (3 as Field));
        assert(clamp(2 as Field, 2 as Field, 5 as Field) == (2 as Field));
        assert(clamp(5 as Field, 2 as Field, 5 as Field) == (5 as Field));
        assert(clamp(5 as Field, 5 as Field, 5 as Field) == (5 as Field));
        
        // Test with min > max (should return max, though unusual setup)
        // The Ord trait doesn't prevent min > max.
        // Current logic: if x < min (e.g. 5 < 10), returns min (10).
        // else if x > max (e.g. 5 > 2), returns max (2).
        // So if min=10, max=2:
        // clamp(1, 10, 2) -> 10 (x < min)
        // clamp(12, 10, 2) -> 2 (x > max, after failing x < min)
        // clamp(5, 10, 2) -> 2 (x < min is false, x > max is true) - this is probably the most sensible.
        assert(clamp(5u64, 10u64, 2u64) == 2u64); // x is between them, but min > max
        assert(clamp(12u64, 10u64, 2u64) == 2u64); // x > min > max
        assert(clamp(1u64, 10u64, 2u64) == 10u64); // x < max < min
    }

    #[test]
    fn test_try_div_ceil_valid() {
        assert(try_div_ceil(1 as u64, 2).unwrap() == 1);
        assert(try_div_ceil(2 as u64, 2).unwrap() == 1);
        assert(try_div_ceil(3 as u64, 2).unwrap() == 2);
        assert(try_div_ceil(4 as u64, 2).unwrap() == 2);
        assert(try_div_ceil(5 as u64, 2).unwrap() == 3);
        assert(try_div_ceil(1337 as u64, 19).unwrap() == 71);
        assert(try_div_ceil(1337 as u64, 7).unwrap() == 191);
        assert(try_div_ceil(10 as u64, 3).unwrap() == 4);
    }

    #[test]
    fn test_try_div_ceil_division_by_zero() {
        let res_u64: Option<u64> = try_div_ceil(10 as u64, 0 as u64);
        assert(res_u64.is_none());

        // Assuming Field also implements Numeric, Add, Div, Rem, Eq
        // (Need to check if Field implements Numeric with zero() and one())
        // Numeric is currently implemented for u8, u16, u32, u64, u128.
        // If we want to test with Field, Field must implement Numeric.
        // For now, testing with u64 is sufficient to demonstrate the Option.
    }

    #[test]
    fn test_try_div_ceil_zero_numerator() {
        assert(try_div_ceil(0 as u64, 5).unwrap() == 0);
    }

    #[test]
    fn test_try_div_ceil_exact_division() {
        assert(try_div_ceil(10 as u64, 2).unwrap() == 5);
    }

    #[test]
    fn test_try_div_ceil_numerator_less_than_denominator() {
        assert(try_div_ceil(5u64, 10u64).unwrap() == 1u64); // 5/10 = 0, ceil = 1
        assert(try_div_ceil(1u64, 100u64).unwrap() == 1u64);
        assert(try_div_ceil(0u64, 100u64).unwrap() == 0u64); // Special case: 0/X = 0
    }

    #[test]
    fn test_try_div_ceil_field() {
        // Field division behaves like modular inverse for q = a/b.
        // (a / b) * b = a (mod p), unless b is 0.
        // div_ceil(a,b) = q if a % b == 0, else q + 1.
        // For Field, a % b is 0 if a is a multiple of b in integer arithmetic,
        // but in field arithmetic, a % b is always 0 because b * (a/b) = a.
        // So, for Field, div_ceil(a,b) should generally be a/b, unless we interpret '%' differently.
        // The current `div_ceil` is `q = a/b; if (a % b == 0) q else q+1`.
        // `a % b` in Noir for fields is `a - (a/b)*b`. This is always 0 if b != 0.
        // So, try_div_ceil for Field will currently always be `a/b`.
        // This test will verify that behavior.

        assert(try_div_ceil(10 as Field, 2 as Field).unwrap() == (5 as Field));
        assert(try_div_ceil(10 as Field, 3 as Field).unwrap() == ((10 as Field) / (3 as Field))); // Should be modular inverse result
        assert(try_div_ceil(7 as Field, 3 as Field).unwrap() == ((7 as Field) / (3 as Field)));
        
        // Test division by zero for Field
        let res_field_div_zero: Option<Field> = try_div_ceil(10 as Field, 0 as Field);
        assert(res_field_div_zero.is_none());

        // Test zero numerator for Field
        assert(try_div_ceil(0 as Field, 5 as Field).unwrap() == (0 as Field));
    }
}
