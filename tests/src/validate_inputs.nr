#[nodash::validate_inputs]
fn my_main(a: Field, b: u64, _s: GoodStruct) -> Field {
    a + b as Field
}

#[test]
fn test_validate_inputs() {
    let result = my_main(1, 2, GoodStruct {});
    assert(result == 3);
}

#[nodash::validate_inputs]
fn main_collections(a: [U120; 1], b: BoundedVec<U120, 2>) -> Field {
    a[0].inner + b.get(0).inner
}

#[test]
fn test_validate_collections() {
    let result = main_collections(
        [U120::new(1)],
        BoundedVec::from_parts([U120::new(2), U120 { inner: 2.pow_32(120) }], 1),
    );
    assert(result == 3);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_validate_array_fail() {
    let _ = main_collections([U120 { inner: 2.pow_32(120) }], BoundedVec::new());
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_validate_bounded_vec_fail() {
    let _ = main_collections(
        [U120::new(1)],
        BoundedVec::from_parts([U120::new(2), U120 { inner: 2.pow_32(120) }], 2),
    );
}

#[nodash::validate_inputs]
fn main_u120(a: U120) -> Field {
    a.inner
}

#[test]
fn test_validate_u120() {
    let inner = 2.pow_32(120) - 1;
    let result = main_u120(U120 { inner });
    assert(result == inner);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_validate_u120_fail() {
    let inner = 2.pow_32(120);
    let result = main_u120(U120 { inner });
    assert(result == inner);
}

struct GoodStruct {}

impl nodash::ValidateInput for GoodStruct {
    fn validate(self) {}
}

struct U120 {
    inner: Field,
}

impl U120 {
    fn new(inner: Field) -> Self {
        inner.assert_max_bit_size::<120>();
        Self { inner }
    }
}

impl nodash::ValidateInput for U120 {
    fn validate(self) {
        let _ = U120::new(self.inner);
    }
}
