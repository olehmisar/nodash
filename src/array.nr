use super::ArrayExtensions;

impl<T, let N: u32> crate::ArrayExtensions<T, N> for [T; N] {
    fn slice<let L: u32>(self, start: u32) -> [T; L] {
        let end = start + L;
        assert(end <= N, "slice: slice end out of bounds");
        let mut result = [self[0]; L];
        for i in 0..L {
            result[i] = self[start + i];
        }
        result
    }

    fn pad_start<let M: u32>(self, pad_value: T) -> [T; M] {
        assert(M >= N, "pad_start: array too long");
        let mut res = [pad_value; M];
        for i in 0..N {
            res[i + M - N] = self[i];
        }
        res
    }

    fn pad_end<let M: u32>(self, pad_value: T) -> [T; M] {
        assert(M >= N, "pad_end: array too long");
        let mut res = [pad_value; M];
        for i in 0..N {
            res[i] = self[i];
        }
        res
    }

    fn enumerate(self) -> [(u32, T); N] {
        let mut res = [(0, std::mem::zeroed()); N];
        for i in 0..N {
            res[i] = (i as u32, self[i]);
        }
        res
    }
}

// TODO: write tests
pub fn pack_bytes<let N: u32>(bytes: [u8; N]) -> [Field; N / 31 + 1] {
    let bytes_padded = bytes.pad_end::<(N / 31 + 1) * 31>(0);
    let mut res = [0 as Field; N / 31 + 1];
    for i in 0..N / 31 + 1 {
        let chunk = bytes_padded.slice::<31>(i * 31);
        res[i] = field_from_bytes(chunk);
    }
    res
}

// copied from https://github.com/AztecProtocol/aztec-packages/blob/a2ed567ad42b237088c110ce12ce8212d5099da2/noir-projects/noir-protocol-circuits/crates/types/src/utils/field.nr#L4
fn field_from_bytes<let N: u32>(bytes: [u8; N]) -> Field {
    assert(bytes.len() < 32, "field_from_bytes: N must be less than 32");
    let mut as_field = 0;
    let mut offset = 1;
    for i in 0..N {
        as_field += (bytes[i] as Field) * offset;
        offset *= 256;
    }
    as_field
}

mod tests {
    use crate::ArrayExtensions;

    #[test]
    fn test_slice() {
        assert([1, 2, 3, 4, 5].slice::<3>(1) == [2, 3, 4]);
    }

    #[test]
    fn test_pad_start() {
        assert([1, 2, 3].pad_start::<5>(0) == [0, 0, 1, 2, 3]);
    }

    #[test]
    fn test_pad_end() {
        assert([1, 2, 3].pad_end::<5>(0) == [1, 2, 3, 0, 0]);
    }

    #[test]
    fn test_enumerate() {
        assert(["a", "b", "c"].enumerate() == [(0, "a"), (1, "b"), (2, "c")]);
    }
}
