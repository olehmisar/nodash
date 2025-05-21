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
    dep::sha256::sha256_var(input.storage(), input.len() as u64)
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
        assert(
            sha256(U8_INPUT_ARR)
                == dep::sha256::sha256_var(U8_INPUT_ARR, U8_INPUT_ARR.len() as u64),
        );
        assert(
            keccak256(U8_INPUT_ARR) == dep::keccak256::keccak256(U8_INPUT_ARR, U8_INPUT_ARR.len()),
        );
    }

    #[test]
    fn test_empty_inputs() {
        // Poseidon2
        let empty_fields_arr: [Field; 0] = [];
        let empty_fields_vec = BoundedVec::<Field,0>::new(); // MaxLen 0 or some small N
        // Note: poseidon2 as_bounded_vec currently uses BoundedVec::from(self), which might not work for MaxLen=0 BoundedVec if it expects N>0.
        // The ArrayOrBoundedVec trait and its impl might need adjustment for N=0 if BoundedVec::from([T;0]) is problematic.
        // However, poseidon::poseidon2::Poseidon2::hash itself should handle len=0.
        // If N=0 for `impl ArrayOrBoundedVec<T, N> for [T; N]`, `BoundedVec::from([T;0])` is fine.
        // If N=0 for `impl ArrayOrBoundedVec<T, N> for BoundedVec<T, N>`, as_bounded_vec(self) is fine.
        // The constraint N for BoundedVec in poseidon2 signature might be the issue.
        // Let's assume N can be 0 for the input type.
        // `poseidon2([])` where N=0 for the input array.
        let expected_poseidon_empty = poseidon::poseidon2::Poseidon2::hash(empty_fields_arr, 0);
        assert(poseidon2(empty_fields_arr) == expected_poseidon_empty);
        // assert(poseidon2(empty_fields_vec) == expected_poseidon_empty); // This needs BoundedVec<Field, 0> which is tricky for the trait.

        // Pedersen
        // std::hash::pedersen_hash requires a non-empty array.
        // So, pedersen([]) will likely fail at the std lib level or due to `[Field;0]` not being allowed.
        // The TODO for pedersen and BoundedVec also hints it's restrictive.
        // If N must be >0 for pedersen, then an empty test isn't applicable for `pedersen` as defined.
        // If N can be 0 (e.g. `pedersen([Field;0])`), let's test it.
        // `std::hash::pedersen_hash` states "input array cannot be empty". So this test should fail if called.
        // For now, we can't directly test pedersen with an empty array in a way that doesn't fail the underlying call.
        // So, skipping direct empty test for `pedersen` unless its definition changes to handle N=0 gracefully or take BoundedVec.

        // SHA256
        let empty_u8_arr: [u8; 0] = [];
        let empty_u8_vec = BoundedVec::<u8,0>::new();
        let expected_sha256_empty = dep::sha256::sha256_var(empty_u8_arr, 0);
        assert(sha256(empty_u8_arr) == expected_sha256_empty);
        // assert(sha256(empty_u8_vec) == expected_sha256_empty);

        // Keccak256
        let expected_keccak256_empty = dep::keccak256::keccak256(empty_u8_arr, 0);
        assert(keccak256(empty_u8_arr) == expected_keccak256_empty);
        // assert(keccak256(empty_u8_vec) == expected_keccak256_empty);
        
        // Known Keccak256 hash of empty string/bytes:
        // "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
        let known_empty_keccak: [u8; 32] = [
            0xc5, 0xd2, 0x46, 0x01, 0x86, 0xf7, 0x23, 0x3c, 0x92, 0x7e, 0x7d, 0xb2, 0xdc, 0xc7, 0x03, 0xc0,
            0xe5, 0x00, 0xb6, 0x53, 0xca, 0x82, 0x27, 0x3b, 0x7b, 0xfa, 0xd8, 0x04, 0x5d, 0x85, 0xa4, 0x70
        ];
        assert(keccak256(empty_u8_arr) == known_empty_keccak);
    }
}
