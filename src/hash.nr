pub fn poseidon2<let N: u32>(input: impl ArrayOrBoundedVec<Field, N>) -> Field {
    let input = input.as_bounded_vec();
    poseidon::poseidon2::Poseidon2::hash(input.storage(), input.len())
}

// TODO: is it possible for pedersen to accept BoundedVec?
pub fn pedersen<let N: u32>(input: [Field; N]) -> Field {
    std::hash::pedersen_hash(input)
}

pub fn sha256<let N: u32>(input: impl ArrayOrBoundedVec<u8, N>) -> [u8; 32] {
    let input = input.as_bounded_vec();
    dep::sha256::sha256_var(input.storage(), input.len())
}

pub fn partial_sha256_interstitial<let N: u32>(
    mut h: [u32; 8],
    input: impl ArrayOrBoundedVec<u8, N>,
) -> [u32; 8] {
    let input = input.as_bounded_vec();
    dep::sha256::partial_sha256_var_interstitial(h, input.storage(), input.len())
}

pub fn partial_sha256_end<let N: u32>(
    mut h: [u32; 8],
    partial_input: impl ArrayOrBoundedVec<u8, N>,
    full_input_len: u32,
) -> [u8; 32] {
    let partial_input = partial_input.as_bounded_vec();
    dep::sha256::partial_sha256_var_end(
        h,
        partial_input.storage(),
        partial_input.len(),
        full_input_len,
    )
}

pub fn keccak256<let N: u32>(input: impl ArrayOrBoundedVec<u8, N>) -> [u8; 32] {
    let input = input.as_bounded_vec();
    dep::keccak256::keccak256(input.storage(), input.len())
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

    global FIELD_INPUT_ARR: [Field; 2] = [1, 2];
    global FIELD_INPUT_VEC: BoundedVec<Field, 2> = BoundedVec::from(FIELD_INPUT_ARR);
    global FIELD_INPUT_VEC_LONGER: BoundedVec<Field, 3> = BoundedVec::from(FIELD_INPUT_ARR);

    global U8_INPUT_ARR: [u8; 2] = [1, 2];
    global U8_INPUT_VEC: BoundedVec<u8, 2> = BoundedVec::from(U8_INPUT_ARR);
    global U8_INPUT_VEC_LONGER: BoundedVec<u8, 3> = BoundedVec::from(U8_INPUT_ARR);

    #[test]
    fn test_equivalence() {
        assert(
            (poseidon2(FIELD_INPUT_ARR) == poseidon2(FIELD_INPUT_VEC)),
            // TODO: is this a bug? https://discord.com/channels/1113924620781883405/1333383938198212659
            // & (poseidon2(FIELD_INPUT_ARR) == poseidon2(FIELD_INPUT_VEC_LONGER)),
        );
        assert(
            (sha256(U8_INPUT_VEC) == sha256(U8_INPUT_ARR))
                & (sha256(U8_INPUT_VEC_LONGER) == sha256(U8_INPUT_ARR)),
        );
        assert(
            (keccak256(U8_INPUT_VEC) == keccak256(U8_INPUT_ARR))
                & (keccak256(U8_INPUT_VEC_LONGER) == keccak256(U8_INPUT_ARR)),
        );
    }

    #[test]
    fn test_against_std() {
        assert(
            poseidon2(FIELD_INPUT_ARR)
                == poseidon::poseidon2::Poseidon2::hash(FIELD_INPUT_ARR, FIELD_INPUT_ARR.len()),
        );
        assert(
            poseidon2(FIELD_INPUT_VEC_LONGER)
                == poseidon::poseidon2::Poseidon2::hash(
                    FIELD_INPUT_VEC_LONGER.storage(),
                    FIELD_INPUT_VEC_LONGER.len(),
                ),
        );
        assert(pedersen(FIELD_INPUT_ARR) == std::hash::pedersen_hash(FIELD_INPUT_ARR));
        assert(sha256(U8_INPUT_ARR) == dep::sha256::sha256_var(U8_INPUT_ARR, U8_INPUT_ARR.len()));
        assert(
            keccak256(U8_INPUT_ARR) == dep::keccak256::keccak256(U8_INPUT_ARR, U8_INPUT_ARR.len()),
        );
    }
}
