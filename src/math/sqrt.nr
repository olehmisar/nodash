use crate::math::numeric::Numeric;
use std::{cmp::Ord, ops::{Add, Div, Mul}};

pub fn sqrt<T>(value: T) -> T
where
    T: Numeric + Mul + Ord + Add + Div,
{
    // Safety: unsafe sqrt is checked to be between bounds
    let r = unsafe {
        let r = sqrt_unconstrained(value);
        assert(value >= r * r);
        let ONE: T = Numeric::one();
        let r_plus_1 = r + ONE;
        assert(value < r_plus_1 * r_plus_1);
        r
    };
    r
}

unconstrained fn sqrt_unconstrained<T>(value: T) -> T
where
    T: Numeric + Ord + Add + Div,
{
    let ZERO: T = Numeric::zero();
    let ONE: T = Numeric::one();
    let TWO = ONE + ONE;
    let THREE = TWO + ONE;

    if value > THREE {
        let mut z = value;
        let mut x = value / TWO + ONE;
        crate::debug::print_field("sqrt_unconstrained init x", x);
        crate::debug::print_field("sqrt_unconstrained init z", z);
        for i in 0..256 { // Limiting iterations for safety in test/debug; 256 should be plenty for u128. Original was 999999999
            if x < z {
                z = x;
                x = (value / x + x) / TWO;
                crate::debug::print_u64("sqrt_unconstrained iter", i as u64);
                crate::debug::print_field("sqrt_unconstrained iter x", x);
                crate::debug::print_field("sqrt_unconstrained iter z", z);
            } else {
                crate::debug::print_u64("sqrt_unconstrained break at iter", i as u64);
                break;
            }
        }
        z
    } else if value > ZERO {
        crate::debug::print_str("sqrt_unconstrained value > 0", "returning 1");
        ONE
    } else {
        ZERO
    }
}

mod tests {
    use crate::math::sqrt::sqrt;

    #[test]
    fn test_sqrt() {
        let value: u128 = 170141183460469231731687303715884105727;
        let result = sqrt(value);
        assert(result == 13043817825332782212);
    }

    #[test]
    fn test_multiple_data_types() {
        assert(sqrt(18 as u8) == 4);
        assert(sqrt(2482737472 as u32) == 49827);
        assert(sqrt(14446244073709551616 as u64) == 3800821499);
        assert(sqrt(1444624284781234073709551616 as u128) == 38008213385809);
    }

    #[test]
    fn test_sqrt_native_u128() {
        assert(sqrt(6 as u128) == 2);
    }

    #[test]
    fn test_sqrt_many_numbers() {
        let pairs: [[u128; 2]] = &[
            [0, 0],
            [1, 1],
            [2, 1],
            [3, 1],
            [4, 2],
            [5, 2],
            [6, 2],
            [7, 2],
            [8, 2],
            [9, 3],
            [10, 3],
            [11, 3],
            [12, 3],
            [13, 3],
            [14, 3],
            [15, 3],
            [16, 4],
            [17, 4],
            [18, 4],
            [19, 4],
            [20, 4],
            [21, 4],
            [22, 4],
            [23, 4],
            [24, 4],
            [25, 5],
            [26, 5],
            [27, 5],
            [28, 5],
            [29, 5],
            [30, 5],
            [31, 5],
            [32, 5],
            [33, 5],
            [34, 5],
            [35, 5],
            [36, 6],
            [37, 6],
            [38, 6],
            [39, 6],
            [40, 6],
            [41, 6],
            [42, 6],
            [43, 6],
            [44, 6],
            [45, 6],
            [46, 6],
            [47, 6],
            [48, 6],
            [49, 7],
            [50, 7],
            [51, 7],
            [52, 7],
            [53, 7],
            [54, 7],
            [55, 7],
            [56, 7],
            [57, 7],
            [58, 7],
            [59, 7],
            [60, 7],
            [61, 7],
            [62, 7],
            [63, 7],
            [64, 8],
            [65, 8],
            [66, 8],
            [67, 8],
            [68, 8],
            [69, 8],
            [70, 8],
            [71, 8],
            // some big numbers
            [9000000000000000000, 3000000000],
            [8274823429819348192323, 90966056470],
        ];

        for pair in pairs {
            let value = pair[0];
            let result = sqrt(value);
            // std::println(f"{pair} {result}");
            assert(result == pair[1]);
        }
    }

    #[test]
    fn test_sqrt_max_values() {
        // u8::max_value() = 255. sqrt(255) = 15 (15*15=225, 16*16=256)
        assert(sqrt(u8::max_value()) == 15u8);

        // u16::max_value() = 65535. sqrt(65535) = 255 (255*255=65025, 256*256=65536)
        assert(sqrt(u16::max_value()) == 255u16);

        // u32::max_value() = 4294967295. sqrt(4294967295) = 65535 (65535*65535 = 4294836225, 65536*65536 = 4294967296)
        assert(sqrt(u32::max_value()) == 65535u32);
        
        // u64::max_value() = 18446744073709551615. sqrt() = 4294967295
        // 4294967295 * 4294967295 = 18446744065119617025
        // 4294967296 * 4294967296 = 18446744073709551616 (which is u64::max_value() + 1)
        assert(sqrt(u64::max_value()) == 4294967295u64);
    }

    #[test]
    fn test_sqrt_near_perfect_squares() {
        // Near 16 (sqrt 4)
        assert(sqrt(15u64) == 3); // 3*3=9, 4*4=16
        assert(sqrt(16u64) == 4);
        assert(sqrt(17u64) == 4); // 4*4=16, 5*5=25

        // Near 100 (sqrt 10)
        assert(sqrt(99u64) == 9);
        assert(sqrt(100u64) == 10);
        assert(sqrt(101u64) == 10);

        // Near a larger square, e.g. 123*123 = 15129
        assert(sqrt(15128u64) == 122); // 122*122 = 14884, 123*123 = 15129
        assert(sqrt(15129u64) == 123);
        assert(sqrt(15130u64) == 123);
    }
}
