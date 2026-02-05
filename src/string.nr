global ASCII_HEX_TABLE: [u8; 16] = "0123456789abcdef".as_bytes();

pub fn field_to_hex(value: Field) -> str<64> {
    let mut result = [0 as u8; 64];
    let bytes = value.to_be_bytes::<32>().map(|x| x as u32);
    for i in 0..bytes.len() {
        result[i * 2] = ASCII_HEX_TABLE[bytes[i] / 16];
        result[i * 2 + 1] = ASCII_HEX_TABLE[bytes[i] % 16];
    }
    From::from(result)
}

#[deprecated("use field_to_hex instead")]
pub fn to_hex_string_bytes(value: Field) -> [u8; 64] {
    field_to_hex(value).as_bytes()
}

global U64_STR_LEN: u32 = 20;
pub fn str_to_u64<T>(arr: T) -> u64
where
    T: Into<[u8; U64_STR_LEN]>,
{
    let arr = arr.into().map(|x| x as u32);

    let mut parsed_number: Field = 0;
    for i in 0..U64_STR_LEN {
        let chr = arr[i];
        if chr != 0 {
            parsed_number *= 10;
            let value = crate::tables::ASCII_TO_NUMBER[arr[i]] as Field;
            parsed_number += value;
        }
    }
    parsed_number as u64
}

pub fn ord(s: str<1>) -> u8 {
    s.as_bytes()[0]
}

mod tests {
    use crate::string::{field_to_hex, ord, str_to_u64};

    #[test]
    fn test_field_to_hex() {
        let my_hash = 0x0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf;
        let expected = "0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf";
        assert_eq(field_to_hex(my_hash), expected);
    }

    #[test]
    fn some_test() {
        let outer_hash = 0x0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf;
        let hex_challenge = field_to_hex(outer_hash);
        let header_prefix: [u8; 26] = "subject:Re: Tx request: 0x".as_bytes();
        let header: [u8; 90] = header_prefix.concat(hex_challenge.as_bytes());
        assert(
            header
                == [
                    115, 117, 98, 106, 101, 99, 116, 58, 82, 101, 58, 32, 84, 120, 32, 114, 101,
                    113, 117, 101, 115, 116, 58, 32, 48, 120, 48, 100, 54, 55, 56, 50, 52, 102, 101,
                    97, 100, 57, 54, 54, 49, 57, 50, 48, 50, 57, 48, 57, 51, 97, 51, 97, 97, 53, 99,
                    55, 49, 57, 102, 50, 98, 56, 48, 50, 54, 50, 99, 52, 102, 49, 52, 97, 53, 99,
                    57, 55, 99, 53, 100, 55, 48, 101, 52, 98, 50, 55, 102, 50, 98, 102,
                ],
        );
    }

    #[test]
    fn test_str_to_u64() {
        let s = "13378584420".as_bytes();
        assert(str_to_u64(s.concat([0; 9])) == 13378584420);
        assert(str_to_u64("02345678912345678912") == 02345678912345678912);
    }

    #[test]
    fn test_char() {
        assert(ord("a") == 97);
    }

}
