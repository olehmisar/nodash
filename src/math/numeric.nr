pub(crate) trait Numeric {
    fn zero() -> Self;
    fn one() -> Self;
}

impl Numeric for u8 {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}

impl Numeric for Field {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}

impl Numeric for u16 {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}

impl Numeric for u32 {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}

impl Numeric for u64 {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}

impl Numeric for u128 {
    fn zero() -> Self {
        0
    }
    fn one() -> Self {
        1
    }
}
