// to avoid naming conflicts with the function names
// TODO: remove this when absolute paths are supported in Noir https://github.com/noir-lang/noir/pull/11471
mod deps {
    pub(crate) use sha256::{partial_sha256_var_end, partial_sha256_var_interstitial, sha256_var};

    pub(crate) fn keccak256_<let N: u32>(input: [u8; N], message_size: u32) -> [u8; 32] {
        keccak256::keccak256(input, message_size)
    }
}

pub fn poseidon2<T, let N: u32>(input: T) -> Field
where
    T: ArrayOrBoundedVec<Field, N>,
{
    let input = input.as_bounded_vec();
    poseidon::poseidon2::Poseidon2::hash(input.storage(), input.len())
}

// TODO: is it possible for pedersen to accept BoundedVec?
pub fn pedersen<let N: u32>(input: [Field; N]) -> Field {
    std::hash::pedersen_hash(input)
}

pub fn sha256<T, let N: u32>(input: T) -> [u8; 32]
where
    T: ArrayOrBoundedVec<u8, N>,
{
    let input = input.as_bounded_vec();
    deps::sha256_var(input.storage(), input.len())
}

pub fn partial_sha256_interstitial<T, let N: u32>(mut h: [u32; 8], input: T) -> [u32; 8]
where
    T: ArrayOrBoundedVec<u8, N>,
{
    let input = input.as_bounded_vec();
    deps::partial_sha256_var_interstitial(h, input.storage(), input.len())
}

pub fn partial_sha256_end<T, let N: u32>(
    mut h: [u32; 8],
    partial_input: T,
    full_input_len: u32,
) -> [u8; 32]
where
    T: ArrayOrBoundedVec<u8, N>,
{
    let partial_input = partial_input.as_bounded_vec();
    deps::partial_sha256_var_end(
        h,
        partial_input.storage(),
        partial_input.len(),
        full_input_len,
    )
}

pub fn keccak256<T, let N: u32>(input: T) -> [u8; 32]
where
    T: ArrayOrBoundedVec<u8, N>,
{
    let input = input.as_bounded_vec();
    deps::keccak256_(input.storage(), input.len())
}

/// Needed because of https://github.com/noir-lang/noir/issues/7054
trait ArrayOrBoundedVec<T, let N: u32> {
    fn as_bounded_vec(self) -> BoundedVec<T, N>;
}

impl<T, let N: u32> ArrayOrBoundedVec<T, N> for [T; N] {
    fn as_bounded_vec(self) -> BoundedVec<T, N> {
        BoundedVec::from(self)
    }
}

impl<T, let N: u32> ArrayOrBoundedVec<T, N> for BoundedVec<T, N> {
    fn as_bounded_vec(self) -> BoundedVec<T, N> {
        self
    }
}

mod tests {
    use crate::hash::{keccak256, pedersen, poseidon2, sha256};
    use super::deps;

    global FIELD_INPUT_ARR: [Field; 2] = [1, 2];
    global FIELD_INPUT_VEC: BoundedVec<Field, 2> = BoundedVec::from(FIELD_INPUT_ARR);
    global FIELD_INPUT_VEC_LONGER: BoundedVec<Field, 3> = BoundedVec::from(FIELD_INPUT_ARR);

    global U8_INPUT_ARR: [u8; 2] = [1, 2];
    global U8_INPUT_VEC: BoundedVec<u8, 2> = BoundedVec::from(U8_INPUT_ARR);
    global U8_INPUT_VEC_LONGER: BoundedVec<u8, 3> = BoundedVec::from(U8_INPUT_ARR);

    #[test]
    fn test_equivalence() {
        assert_eq(poseidon2(FIELD_INPUT_ARR), poseidon2(FIELD_INPUT_VEC));
        assert_eq(poseidon2(FIELD_INPUT_ARR), poseidon2(FIELD_INPUT_VEC_LONGER));
        assert_eq(sha256(U8_INPUT_VEC), sha256(U8_INPUT_ARR));
        assert_eq(sha256(U8_INPUT_VEC_LONGER), sha256(U8_INPUT_ARR));
        assert_eq(keccak256(U8_INPUT_VEC), keccak256(U8_INPUT_ARR));
        assert_eq(keccak256(U8_INPUT_VEC_LONGER), keccak256(U8_INPUT_ARR));
    }

    #[test]
    fn test_against_std() {
        assert_eq(
            poseidon2(FIELD_INPUT_ARR),
            poseidon::poseidon2::Poseidon2::hash(FIELD_INPUT_ARR, FIELD_INPUT_ARR.len()),
        );
        assert_eq(
            poseidon2(FIELD_INPUT_VEC_LONGER),
            poseidon::poseidon2::Poseidon2::hash(
                FIELD_INPUT_VEC_LONGER.storage(),
                FIELD_INPUT_VEC_LONGER.len(),
            ),
        );
        assert_eq(pedersen(FIELD_INPUT_ARR), std::hash::pedersen_hash(FIELD_INPUT_ARR));
        assert_eq(sha256(U8_INPUT_ARR), deps::sha256_var(U8_INPUT_ARR, U8_INPUT_ARR.len()));
        assert_eq(keccak256(U8_INPUT_ARR), deps::keccak256_(U8_INPUT_ARR, U8_INPUT_ARR.len()));
    }
}
