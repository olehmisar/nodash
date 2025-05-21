// Harness main for CLI
use nodash::Error; 
use nodash::string::{
    try_str_to_u64, U64_STR_LEN,
    try_str_to_u128, U128_DEC_STR_LEN,
    try_hex_str_to_u128, U128_HEX_STR_LEN,
    field_to_hex,
    bytes_to_hex_str,
    try_hex_str_to_bytes,
    try_parse_bool, MAX_BOOL_STR_LEN
};
use nodash::math::try_div_ceil;
use nodash::hash::{keccak256, sha256}; 
use nodash::tables::ASCII_TO_NUMBER; // For CSV parsing helper

// Helper to parse comma-separated u8 string into a BoundedVec for hashing/byte ops
// Max 256 bytes for CLI simplicity, adjust as needed.
const MAX_BYTE_ARRAY_LEN_CLI: u32 = 256; // Max number of u8s
const MAX_CSV_STR_LEN_CLI: u32 = MAX_BYTE_ARRAY_LEN_CLI * 4; // Max string length for CSV (e.g., "255," is 4 chars)

fn parse_u8_csv_to_bounded_vec(csv_str: str<MAX_CSV_STR_LEN_CLI>) -> BoundedVec<u8, MAX_BYTE_ARRAY_LEN_CLI> {
    let mut result_vec = BoundedVec::<u8, MAX_BYTE_ARRAY_LEN_CLI>::new();
    let bytes = csv_str.as_bytes();
    let mut current_num_str_bytes = BoundedVec::<u8, 3>::new(); // Max 3 chars for u8 ("255")
    let mut i = 0;

    while i < csv_str.len() { // Use csv_str.len() which is the actual length of string data
        if result_vec.len() == MAX_BYTE_ARRAY_LEN_CLI { break; } // Safety break
        let char_byte = bytes[i];
        if char_byte == 0 { break; } // Null terminator for string

        if char_byte == (',' as u8) {
            if current_num_str_bytes.len() > 0 {
                let mut val: u64 = 0;
                // Convert current_num_str_bytes to u8
                let mut temp_str_val = [0u8; 3]; // for str_to_u64 which takes array
                for k in 0..current_num_str_bytes.len() { temp_str_val[k] = current_num_str_bytes.get(k); }
                
                // Simplified parsing for the number string part of CSV
                // This is a bit of a workaround as try_str_to_u64 expects a fixed size input.
                // For robust CSV, one might need more complex parsing or a dedicated CSV utility.
                let mut num_val_u64: u64 = 0;
                for k_idx in 0..current_num_str_bytes.len() {
                    let digit_char = current_num_str_bytes.get(k_idx);
                    if digit_char >= ('0' as u8) && digit_char <= ('9' as u8) {
                         num_val_u64 = num_val_u64 * 10 + (ASCII_TO_NUMBER[digit_char] as u64);
                    } else { /* handle error or skip */ }
                }

                if num_val_u64 <= 255 { // u8 max
                    result_vec.push(num_val_u64 as u8);
                } else { /* handle error: number too large for u8 */ }
                current_num_str_bytes.clear();
            }
        } else if char_byte >= ('0' as u8) && char_byte <= ('9' as u8) {
            if current_num_str_bytes.len() < 3 { // Prevent overflow for u8 string buffer
                current_num_str_bytes.push(char_byte);
            }
        } // Ignore other characters for simplicity
        i += 1;
    }
    // Process last number if any
    if current_num_str_bytes.len() > 0 && result_vec.len() < MAX_BYTE_ARRAY_LEN_CLI {
        let mut num_val_u64: u64 = 0;
        for k_idx in 0..current_num_str_bytes.len() {
            let digit_char = current_num_str_bytes.get(k_idx);
             if digit_char >= ('0' as u8) && digit_char <= ('9' as u8) {
                num_val_u64 = num_val_u64 * 10 + (ASCII_TO_NUMBER[digit_char] as u64);
            } else { /* handle error */ }
        }
        if num_val_u64 <= 255 {
             result_vec.push(num_val_u64 as u8);
        } else { /* handle error */ }
    }
    result_vec
}


fn main(command: str<20>, arg1_str: str<MAX_CSV_STR_LEN_CLI>, arg2_str: str<U64_STR_LEN>) {
    if command == "parse_u64" {
        let mut arg_bytes = [0u8; U64_STR_LEN];
        let input_bytes = arg1_str.as_bytes();
        for i in 0..arg1_str.len() { // Use actual string length
            if i < U64_STR_LEN { arg_bytes[i] = input_bytes[i]; } else { break; }
        }
        match try_str_to_u64(arg_bytes) {
            Result::ok(val) => { std::println("RESULT:"); std::println(val); },
            Result::err(e) => { 
                if e == Error::InvalidStringFormat { std::println("ERROR_TYPE:InvalidStringFormat"); }
                else if e == Error::NumericOverflow { std::println("ERROR_TYPE:NumericOverflow"); }
                else { std::println("ERROR:UnknownParseErrorForU64"); }
            },
        }
    } else if command == "parse_u128" {
        let mut arg_bytes = [0u8; U128_DEC_STR_LEN];
        let input_bytes = arg1_str.as_bytes();
        for i in 0..arg1_str.len() {
             if i < U128_DEC_STR_LEN { arg_bytes[i] = input_bytes[i]; } else { break; }
        }
        match try_str_to_u128(str::from_bytes(arg_bytes)) { 
            Result::ok(val) => { std::println("RESULT:"); std::println(val); },
            Result::err(e) => { 
                if e == Error::InvalidStringFormat { std::println("ERROR_TYPE:InvalidStringFormat"); }
                else if e == Error::NumericOverflow { std::println("ERROR_TYPE:NumericOverflow"); }
                else { std::println("ERROR:UnknownParseErrorForU128"); }
            },
        }
    } else if command == "hex_to_u128" {
        let mut arg_bytes = [0u8; U128_HEX_STR_LEN];
        let input_bytes = arg1_str.as_bytes();
         for i in 0..arg1_str.len() {
             if i < U128_HEX_STR_LEN { arg_bytes[i] = input_bytes[i]; } else { break; }
        }
         match try_hex_str_to_u128(str::from_bytes(arg_bytes)) {
            Result::ok(val) => { std::println("RESULT:"); std::println(val); },
            Result::err(e) => { 
                if e == Error::InvalidStringFormat { std::println("ERROR_TYPE:InvalidStringFormat"); }
                else if e == Error::NumericOverflow { std::println("ERROR_TYPE:NumericOverflow"); }
                else { std::println("ERROR:UnknownParseErrorForHexU128"); }
            },
        }
    } else if command == "field_to_hex" {
        // Simplified parsing for decimal field string for CLI
        let mut val: Field = 0;
        let f_bytes = arg1_str.as_bytes();
        for i in 0..arg1_str.len() {
            if f_bytes[i] >= ('0' as u8) && f_bytes[i] <= ('9' as u8) {
                val = val * 10 + ((f_bytes[i] - ('0' as u8)) as Field);
            } else { /* error or ignore non-digits for simplicity */ }
        }
        std::println("RESULT:");
        std::println(field_to_hex(val));
    } else if command == "bytes_to_hex" {
        let byte_vec = parse_u8_csv_to_bounded_vec(arg1_str);
        std::print("RESULT:"); 
        for i in 0..byte_vec.len() {
            let b = byte_vec.get_unchecked(i); // Use get_unchecked as len is known
            let hex_pair: str<2> = bytes_to_hex_str([b]);
            std::print(hex_pair);
        }
        std::println(""); 
    } else if command == "hex_to_bytes" {
        let hex_input_len = arg1_str.len();
        if hex_input_len % 2 != 0 { std::println("ERROR:HexStringMustHaveEvenLength"); return; }
        if hex_input_len == 0 { std::println("RESULT:"); return; }

        // Determine N for try_hex_str_to_bytes based on input length.
        // This requires dynamic N or multiple function variants if N is comptime.
        // For CLI simplicity, handling up to 32 bytes (64 hex chars).
        if hex_input_len == 2 { // N=1
            match try_hex_str_to_bytes(arg1_str.slice_to_str::<2>()) {
                 Result::ok(res) => { std::println("RESULT:"); std::println(res[0]); },
                 Result::err(_) => { std::println("ERROR_TYPE:InvalidStringFormat");}
            }
        } else if hex_input_len == 4 { // N=2
             match try_hex_str_to_bytes(arg1_str.slice_to_str::<4>()) {
                 Result::ok(res) => { std::print("RESULT:"); std::print(res[0]); std::print(","); std::println(res[1]);},
                 Result::err(_) => { std::println("ERROR_TYPE:InvalidStringFormat");}
            }
        } else if hex_input_len == 64 { // N=32
             match try_hex_str_to_bytes(arg1_str.slice_to_str::<64>()) {
                 Result::ok(res) => { 
                    std::print("RESULT:"); 
                    for i in 0..res.len() { 
                        std::print(res[i]); if i < res.len()-1 {std::print(",");}
                    }
                    std::println("");
                 },
                 Result::err(_) => { std::println("ERROR_TYPE:InvalidStringFormat");}
            }
        } // Add more cases or use a generic approach if possible for CLI
         else {
            std::println("ERROR:UnsupportedHexLengthForCliExample");
        }

    } else if command == "keccak256_bytes" {
        let byte_vec = parse_u8_csv_to_bounded_vec(arg1_str);
        let hash_val: [u8; 32] = keccak256(byte_vec); // keccak256 can take BoundedVec
        std::print("RESULT:");
        let hex_str: str<64> = bytes_to_hex_str(hash_val);
        std::println(hex_str);
    } else if command == "sha256_bytes" {
        let byte_vec = parse_u8_csv_to_bounded_vec(arg1_str);
        let hash_val: [u8; 32] = sha256(byte_vec);
        std::print("RESULT:");
        let hex_str: str<64> = bytes_to_hex_str(hash_val);
        std::println(hex_str);
    } else if command == "parse_bool" {
        let mut bv = BoundedVec::<u8, MAX_BOOL_STR_LEN>::new();
        let input_bytes = arg1_str.as_bytes();
        for i in 0..arg1_str.len() {
            if bv.len() < MAX_BOOL_STR_LEN { bv.push(input_bytes[i]); } else { break; }
        }
        match try_parse_bool(bv) {
            Option::some(b_val) => {
                std::print("RESULT:");
                if b_val { std::println("true"); } else { std::println("false"); }
            },
            Option::none() => { std::println("ERROR:InvalidBooleanString"); }
        }
    } else if command == "div_ceil" {
        let mut num_a_bytes = [0u8; U64_STR_LEN];
        let input_a_bytes = arg1_str.as_bytes();
        for i in 0..arg1_str.len() { if i < U64_STR_LEN { num_a_bytes[i] = input_a_bytes[i]; } else {break;}}
        
        let mut num_b_bytes = [0u8; U64_STR_LEN];
        let input_b_bytes = arg2_str.as_bytes();
        for i in 0..arg2_str.len() { if i < U64_STR_LEN { num_b_bytes[i] = input_b_bytes[i]; } else {break;}}

        let res_a = try_str_to_u64(num_a_bytes);
        let res_b = try_str_to_u64(num_b_bytes);

        if res_a.is_err() || res_b.is_err() {
            std::println("ERROR:InvalidNumberInputForDivCeil");
        } else {
            match try_div_ceil(res_a.unwrap(), res_b.unwrap()) {
                Option::some(val) => { std::println("RESULT:"); std::println(val); },
                Option::none() => { std::println("ERROR:DivisionByZero"); }
            }
        }
    }
    else {
        std::println("ERROR:UnknownCommand");
    }
}
