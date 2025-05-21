# Nodash - Lodash for Noir

Nodash is a utility library for the [Noir programming language](https://noir-lang.org/), inspired by Lodash. It provides a collection of helpful functions to simplify common data manipulations, type conversions, cryptographic operations, and enhance safety through robust error handling and input validation.

## Installation

Add the following to your `Nargo.toml` dependencies:

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "v0.42.0" } # Replace with desired tag or commit
```

Then, import utilities in your Noir code, e.g.:
```rust
use nodash::{try_str_to_u64, ArrayExtensions, Error};
```

## Table of Contents

- [Core Concepts](#core-concepts)
  - [Error Handling](#error-handling)
  - [Input Validation](#input-validation)
- [API Reference](#api-reference)
  - [Array Utilities (`ArrayExtensions`)](#array-utilities-arrayextensions)
  - [Conversion Utilities (`TryFrom`)](#conversion-utilities-tryfrom)
  - [Hashing Utilities](#hashing-utilities)
  - [Math Utilities](#math-utilities)
  - [String Utilities](#string-utilities)
  - [Solidity Utilities](#solidity-utilities)
  - [Byte Packing](#byte-packing)
- [Command Line Interface (CLI)](#command-line-interface-cli)
- [Developer Information](#developer-information)
  - [Running Tests](#running-tests)
  - [Debugging with `debug_print`](#debugging-with-debug_print)
  - [Code Formatting](#code-formatting)
  - [Independent Setup](#independent-setup)

## Core Concepts

### Error Handling

Nodash functions aim for safety and predictability. Our error handling philosophy is:

1.  **`Result<T, Error>` for Recoverable Errors:** Functions that can fail due to invalid input data (e.g., parsing a malformed string, numeric overflow during conversion) return a `Result<T, nodash::Error>`. This allows you to gracefully handle errors.
    ```rust
    use nodash::{try_str_to_u64, Error, U64_STR_LEN}; // Assuming U64_STR_LEN is exported or known

    // Helper to prepare fixed-size byte array for try_str_to_u64
    fn string_to_u64_input_bytes(s: str<20>) -> [u8; U64_STR_LEN] {
        let mut bytes = [0u8; U64_STR_LEN];
        let s_bytes = s.as_bytes();
        let len_to_copy = if s_bytes.len() > U64_STR_LEN { U64_STR_LEN } else { s_bytes.len() };
        for i in 0..len_to_copy {
            bytes[i] = s_bytes[i];
        }
        bytes
    }

    fn main(s_val: str<20>) -> u64 { // Example input string
        match try_str_to_u64(string_to_u64_input_bytes(s_val)) {
            Result::ok(value) => value,
            Result::err(error_type) => {
                // Handle specific errors
                if error_type == Error::InvalidStringFormat {
                    std::println("Error: String format is invalid!");
                } else if error_type == Error::NumericOverflow {
                    std::println("Error: Number is too large!");
                }
                0 // Return a default or propagate error
            }
        }
    }
    ```
    The `nodash::Error` enum (`use nodash::Error;`) includes variants like:
    - `InvalidStringFormat`: For malformed string inputs during parsing.
    - `NumericOverflow`: When a parsed number exceeds the target type's capacity.
    - `ValueOutOfBounds`: For type conversions where the input value cannot fit.

2.  **`Option<T>` for Optional Values:** Functions that might not return a value under normal conditions (e.g., `try_slice` if bounds are invalid, `try_parse_bool` for non-boolean strings) return an `Option<T>`.
    ```rust
    use nodash::ArrayExtensions;

    fn main(arr: [Field; 5], start: u32) { // L for try_slice must be comptime
        let maybe_slice: Option<[Field; 2]> = arr.try_slice::<2>(start); 
        if maybe_slice.is_some() {
            let slice = maybe_slice.unwrap();
            // work with slice
            std::println("Slice successful!");
        } else {
            std::println("Failed to get slice (e.g. out of bounds).");
        }
    }
    ```

3.  **`assert` for Programmer Errors:** `assert` statements are used for precondition violations (e.g., incorrect array length parameters where lengths are fixed by generics) or internal logic errors. These represent bugs in the calling code or the library itself and are not expected to be handled at runtime by the caller.

### Input Validation

Noir's `main` function inputs are not automatically validated against struct invariants (e.g., a `U120` struct ensuring its inner `Field` is <= 2<sup>120</sup>-1). Nodash provides `#[validate_inputs]` to enforce these.

```rust
use nodash::{validate_inputs, ValidateInput};

struct U120 {
    inner: Field,
}

impl U120 {
    fn new(inner: Field) -> Self {
        // This assertion defines the invariant for U120
        inner.assert_max_bit_size::<120>();
        Self { inner }
    }
}

// Implement the ValidateInput trait for your struct
impl ValidateInput for U120 {
    fn validate(self) {
        // Reuse the constructor's validation logic
        U120::new(self.inner);
    }
}

// Apply the attribute to your main function
#[validate_inputs]
fn main(a: U120, b: Field) { // b will also be validated if it had a ValidateInput impl
    // Now, `a` is guaranteed to be a valid U120
    std::println("Input 'a' is valid.");
}
```
If an invalid `U120` is passed from JavaScript, the `#[validate_inputs]` attribute will trigger the `validate()` method, causing the `assert_max_bit_size` to fail, thus protecting your circuit logic.

## API Reference

### Array Utilities (`ArrayExtensions`)

Import with `use nodash::ArrayExtensions;`. These methods are available on fixed-size arrays.

- **`slice<let L: u32>(self, start: u32) -> [T; L]`**
  Returns a slice of the array. Panics if `start + L` is out of bounds. For a fallible version, see `try_slice`.
  ```rust
  assert([1, 2, 3, 4, 5].slice::<3>(1) == [2, 3, 4]);
  ```

- **`try_slice<let L: u32>(self, start: u32) -> Option<[T; L]>`**
  Returns an `Option` containing a slice of the array. Returns `None` if `start + L` is out of bounds or other slice conditions are not met (e.g., `start > N` or internal overflow during bounds calculation).
  ```rust
  let arr = [10, 20, 30, 40, 50];
  let s: Option<[Field;3]> = arr.try_slice::<3>(1); // L must be known at compile time
  if s.is_some() {
      assert(s.unwrap() == [20, 30, 40]);
  }
  ```

- **`pad_start<let M: u32>(self, pad_value: T) -> [T; M]`**
  Pads the start of the array with `pad_value` up to length `M`. Panics if `M < self.len()`.
  ```rust
  assert([1, 2, 3].pad_start::<5>(0) == [0, 0, 1, 2, 3]);
  ```

- **`pad_end<let M: u32>(self, pad_value: T) -> [T; M]`**
  Pads the end of the array with `pad_value` up to length `M`. Panics if `M < self.len()`.
  ```rust
  assert([1, 2, 3].pad_end::<5>(0) == [1, 2, 3, 0, 0]);
  ```

- **`enumerate(self) -> [(u32, T); N]`**
  Returns an array of (index, value) tuples.
  ```rust
  assert(["a", "b", "c"].enumerate() == [(0, "a"), (1, "b"), (2, "c")]);
  ```

- **`contains(self, value: T) -> bool where T: Eq`**
  Checks if the array contains the given value.
  ```rust
  assert([1, 2, 3].contains(2) == true);
  assert(["a", "b"].contains("c") == false);
  ```

- **`reverse(self) -> [T; N]`**
  Returns a new array with elements in reverse order.
  ```rust
  assert([1, 2, 3].reverse() == [3, 2, 1]);
  ```

### Conversion Utilities (`TryFrom`)

Import with `use nodash::{TryFrom, Error};`. This trait provides fallible conversions.

- **`OutputType::try_from(input: InputType) -> Result<OutputType, Error>`**
  Examples:
  ```rust
  // Field to u8
  let f_valid = 123 as Field;
  let u8_val: u8 = u8::try_from(f_valid).unwrap();
  assert(u8_val == 123);

  let f_invalid = 256 as Field;
  let u8_res: Result<u8, Error> = u8::try_from(f_invalid);
  assert(u8_res.is_err());
  assert(u8_res.err().unwrap() == Error::ValueOutOfBounds);

  // Integer down-casting (e.g., u16 to u8)
  let u16_val: u16 = 255;
  assert(u8::try_from(u16_val).unwrap() == 255u8);

  let u16_overflow: u16 = 256;
  let u8_res_overflow: Result<u8, Error> = u8::try_from(u16_overflow);
  assert(u8_res_overflow.is_err());
  assert(u8_res_overflow.err().unwrap() == Error::ValueOutOfBounds);
  
  // Field to bool
  assert(bool::try_from(1 as Field).unwrap() == true);
  assert(bool::try_from(0 as Field).unwrap() == false);
  let bool_res_err: Result<bool, Error> = bool::try_from(2 as Field);
  assert(bool_res_err.is_err());
  assert(bool_res_err.err().unwrap() == Error::ValueOutOfBounds);
  ```
  Currently implemented for:
  - `Field` to `u8, u16, u32, u64, u128` (and `i8, i16, i32, i64` with limitations for negative Field values - see code comments).
  - `Field` to `bool` (`0`->`false`, `1`->`true`).
  - Unsigned integer down-casts (e.g., `u16`->`u8`, `u128`->`u64`).
  - Signed integer down-casts (e.g., `i16`->`i8`).

### Hashing Utilities

- **`poseidon2<let N: u32>(input: impl ArrayOrBoundedVec<Field, N>) -> Field`**
  ```rust
  use nodash::poseidon2;
  let hash = poseidon2([10 as Field, 20 as Field]);
  ```
- **`pedersen<let N: u32>(input: [Field; N]) -> Field`**
  Note: Requires `N > 0` due to underlying stdlib constraints.
  ```rust
  use nodash::pedersen;
  let hash = pedersen([10 as Field, 20 as Field]);
  ```
- **`sha256<let N: u32>(input: impl ArrayOrBoundedVec<u8, N>) -> [u8; 32]`**
  (Expensive in Noir, use Poseidon if possible)
  ```rust
  use nodash::sha256;
  let hash = sha256([10u8, 20u8]);
  ```
- **`keccak256<let N: u32>(input: impl ArrayOrBoundedVec<u8, N>) -> [u8; 32]`**
  (Expensive in Noir, use Poseidon if possible)
  ```rust
  use nodash::keccak256;
  let hash = keccak256([10u8, 20u8]);
  ```

### Math Utilities

- **`sqrt<T>(value: T) -> T`** (where `T: Numeric + Mul + Ord + Add + Div`)
  Calculates the integer square root (floored).
  ```rust
  use nodash::math::sqrt; 
  assert(sqrt(8u64) == 2);
  ```
- **`clamp<T>(x: T, min: T, max: T) -> T`** (where `T: Ord`)
  Clamps `x` to be within `[min, max]`.
  ```rust
  use nodash::math::clamp;
  assert(clamp(1u64, 2u64, 3u64) == 2u64);
  ```
- **`try_div_ceil<T>(a: T, b: T) -> Option<T>`** (where `T: Add + Div + Rem + Eq + Numeric`)
  Calculates `a / b` rounded up. Returns `None` if `b` is zero. Implemented for `u8-u128` and `Field`.
  Note: For `Field`, due to modular arithmetic, `a % b` is always `0` if `b != 0`. So `try_div_ceil(a,b)` effectively returns `a/b` for `Field`s.
  ```rust
  use nodash::math::try_div_ceil;
  assert(try_div_ceil(10u64, 3u64).unwrap() == 4u64);
  assert(try_div_ceil(10u64, 0u64).is_none());
  ```

### String Utilities

Many string parsing functions return `Result<T, Error>` or `Option<T>`. Input strings for parsing are typically expected as fixed-size byte arrays `[u8; MAX_LEN]`, often null-padded if the actual string content is shorter.

- **`field_to_hex(value: Field) -> str<64>`**
  Converts a `Field` to a hex string (64 chars, no "0x" prefix).
  ```rust
  use nodash::string::field_to_hex;
  let f_val = 0x123abc as Field;
  // Example: field_to_hex(f_val) might be "00...00123abc"
  ```
- **`try_str_to_u64(arr_provider: impl Into<[u8; U64_STR_LEN]>) -> Result<u64, Error>`**
  Converts a decimal string (as bytes, typically null-padded) to `u64`. `U64_STR_LEN` is 20.
  ```rust
  use nodash::string::{try_str_to_u64, U64_STR_LEN};
  
  // Example helper to create the [u8; N] input
  fn string_to_fixed_bytes<let N: u32>(s: &str) -> [u8; N] {
      let mut bytes = [0u8; N];
      let s_bytes = s.as_bytes();
      let len_to_copy = if s_bytes.len() > N { N } else { s_bytes.len() };
      for i in 0..len_to_copy {
          bytes[i] = s_bytes[i];
      }
      bytes
  }
  let num_res = try_str_to_u64(string_to_fixed_bytes::<U64_STR_LEN>("12345"));
  assert(num_res.unwrap() == 12345);
  ```
- **`try_str_to_u128`, `try_str_to_field_decimal`**: Similar to `try_str_to_u64` for `u128` (using `U128_DEC_STR_LEN = 39`) and `Field` (using `FIELD_DEC_STR_LEN = 77`).
- **`try_hex_str_to_u128`, `try_hex_str_to_field`**: Parse hex strings to `u128` (using `U128_HEX_STR_LEN = 32`) or `Field` (using `FIELD_HEX_STR_LEN = 64`). Input hex strings should not have "0x" prefix.
- **`ord(s: str<1>) -> u8`**: Returns ASCII value of a character.
  ```rust
  use nodash::string::ord;
  assert(ord("a") == 97);
  ```
- **`try_parse_bool(s_vec: BoundedVec<u8, MAX_BOOL_STR_LEN>) -> Option<bool>`**
  Parses "true", "false", "1", "0" (case-insensitive for words) into a boolean. `MAX_BOOL_STR_LEN` is 5.
  ```rust
  use nodash::string::try_parse_bool;
  assert(try_parse_bool(BoundedVec::from_slice("true".as_bytes())).unwrap() == true);
  assert(try_parse_bool(BoundedVec::from_slice("No".as_bytes())).is_none());
  ```
- **`uN_to_dec_str(val: uN) -> str<MAX_LEN>`**: Converts `u8, u16, u32, u64, u128` to zero-padded decimal strings.
  (e.g., `u8_to_dec_str -> str<3>`, `u16_to_dec_str -> str<5>`, `u32_to_dec_str -> str<10>`, `u64_to_dec_str -> str<20>`, `u128_to_dec_str -> str<39>`)
  ```rust
  use nodash::string::u64_to_dec_str; // and others like u8_to_dec_str
  assert(u64_to_dec_str(123) == "00000000000000000123"); // For u64
  ```
- **`bytes_to_hex_str<let N: u32, let M: u32>(bytes: [u8; N]) -> str<M>`**: Converts byte array to hex string. `M` must be `2*N`.
  ```rust
  use nodash::string::bytes_to_hex_str;
  assert(bytes_to_hex_str([0xDE, 0xAD]) == "dead");
  ```
- **`try_hex_str_to_bytes<let M: u32, let N: u32>(hex_str: str<M>) -> Result<[u8; N], Error>`**: Converts hex string to byte array. `M` must be even, `N` must be `M/2`.
  ```rust
  use nodash::string::try_hex_str_to_bytes;
  let bytes_res = try_hex_str_to_bytes("deadbf");
  assert(bytes_res.unwrap() == [0xDE, 0xAD, 0xBF]);
  ```
  *(Note: `uN_to_hex_str` functions are also available for direct number-to-hex string conversion.)*

### Solidity Utilities

Namespace: `nodash::solidity`

- **`encode_with_selector<let N: u32>(selector: u32, args: [Field; N]) -> [u8; SELECTOR_LENGTH + N * 32]`**
  Equivalent to `abi.encodeWithSelector` in Solidity. `SELECTOR_LENGTH` is 4.
  ```rust
  use nodash::solidity::encode_with_selector;
  let sel: u32 = 0xa9059cbb; // transfer(address,uint256)
  let args_arr: [Field; 2] = [0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, 123];
  let encoded_data = encode_with_selector(sel, args_arr);
  ```
- **`encode_with_selector_bytes<let N: u32>(selector: [u8; SELECTOR_LENGTH], args: [Field; N]) -> ...`**: Similar, but takes selector as bytes.
- **`to_selector<let N: u32>(signature: str<N>) -> [u8; SELECTOR_LENGTH]`**
  Generates a 4-byte function selector from a string signature (e.g., "transfer(address,uint256)").
  ```rust
  use nodash::solidity::to_selector;
  let sel_bytes = to_selector("myFunction(uint256)");
  ```

### Byte Packing

- **`pack_bytes<let N: u32>(bytes: [u8; N]) -> [Field; K]`**
  Packs `[u8; N]` into `[Field; K]`. `K` is `N/31 + 1`. Each Field element (except possibly the last) contains up to 31 bytes, little-endian. This is useful for hashing byte arrays efficiently.
  **Important Note:** Due to the `N/31 + 1` formula for `K`, if `N` is a non-zero multiple of 31 (e.g., N=31, N=62), the resulting `[Field; K]` will have an extra field containing zero at the end. This behavior has been confirmed by tests and might be refined in future versions for optimization. For `N=0`, it returns `[Field; 1]` containing a single zero Field.
  ```rust
  use nodash::pack_bytes;
  let my_bytes: [u8; 32] = [0xAB; 32]; // Example: 32 bytes
  let packed_fields = pack_bytes(my_bytes); // Results in [Field; 2] (32/31 + 1 = 1 + 1 = 2)
  ```

## Command Line Interface (CLI)

Nodash provides a simple command-line wrapper script, `nodash_cli.sh`, for accessing some of its functionalities directly from your shell. This is useful for quick tests, scripting, or integrating Nodash features into other workflows without writing Noir code.

**Caveat:** End-to-end testing of the CLI script with `nargo execute` was not possible in the development environment due to the unavailability of `nargo`. The documented behavior is based on the script's design and the Noir harness implementation. Please verify functionality in your own environment with `nargo` installed.

**Prerequisites:**
- **Noir (nargo):** The CLI script uses `nargo execute` to run a Noir harness. Ensure `nargo` is installed and available in your system's PATH. Refer to the [official Noir documentation](https://noir-lang.org/docs/getting_started/installation/) for installation instructions.
- The script must be run from the root of the `nodash` project directory.

**How to Run:**
```bash
./nodash_cli.sh <subcommand> [args...]
```
Make sure the script is executable: `chmod +x nodash_cli.sh`.

**Example Commands:**
```bash
# Parse a u64 string
./nodash_cli.sh parse_u64 "1234567890"

# Convert a Field (as decimal) to hex
./nodash_cli.sh field_to_hex "123"

# Convert comma-separated byte values to hex
./nodash_cli.sh bytes_to_hex "10,20,255"

# Get Keccak256 hash of bytes
./nodash_cli.sh keccak256_bytes "1,2,3"

# Parse a boolean string
./nodash_cli.sh parse_bool "TRUE"

# Calculate ceiling division for u64 numbers
./nodash_cli.sh div_ceil "100" "8"
```

**Available Subcommands:**
- `parse_u64 <string_value>`: Parses a decimal string to u64.
- `parse_u128 <string_value>`: Parses a decimal string to u128.
- `hex_to_u128 <hex_string_value>`: Parses a hex string (no "0x" prefix) to u128.
- `field_to_hex <field_dec_string>`: Converts a decimal Field string to its hex representation.
- `bytes_to_hex <u8_csv_string>`: Converts comma-separated u8 decimal values (e.g., "10,20,255") to a hex string.
- `hex_to_bytes <hex_string>`: Converts a hex string to comma-separated u8 decimal values (max 64 hex chars for CLI due to harness limitations).
- `keccak256_bytes <u8_csv_string>`: Hashes comma-separated u8 values with Keccak256 and outputs the hex hash.
- `sha256_bytes <u8_csv_string>`: Hashes comma-separated u8 values with SHA256 and outputs the hex hash.
- `parse_bool <string_value>`: Parses 'true', 'false', '1', '0' (case-insensitive for words) to boolean.
- `div_ceil <num_a_u64> <num_b_u64>`: Calculates ceil(num_a / num_b) for u64 numbers.

The CLI will output results in the format `RESULT:value` for success, or `Error:message` / `ERROR_TYPE:Variant` for known errors from Nodash functions. If `nargo` execution fails (or `nargo` is not found), the script will output an error message.

## Developer Information

### Running Tests

To run the comprehensive test suite for Nodash:

**1. Noir Library Tests:**
```bash
nargo test
```
This command executes all unit tests (`#[test]`) within the `src` directory and the `tests` directory (for integration-style tests of the Noir library itself).

**2. CLI Wrapper Tests:**
The CLI wrapper has its own test script (`tests/cli/test_cli.sh`). Ensure `nodash_cli.sh` and `tests/cli/test_cli.sh` are executable (`chmod +x`).
```bash
./tests/cli/test_cli.sh
```
This script runs various `nodash_cli.sh` commands and checks their output and exit codes. It requires `nargo` to be available. If `nargo` is not found, the tests will fail, correctly indicating this environmental issue.

### Debugging with `debug_print`

Nodash includes a conditional debug printing utility, primarily intended for developers working on `nodash` itself or those needing deep inspection of its internal behavior. When enabled, certain functions will print intermediate values or execution path information to `stdout` during `nargo test` or `nargo execute`.

**How to Enable:**
Compile or run your tests with the `debug_print` feature flag:
```bash
# For tests
nargo test --features debug_print

# For building a binary (like the CLI harness)
nargo build --features debug_print

# For executing
nargo execute <witness_name> --features debug_print
```
When the `debug_print` feature is not active (default), the debug print calls compile to no-ops and have no performance overhead. See `src/debug.nr` for the helper functions used.

### Code Formatting
It is recommended to format your Noir code using `nargo fmt` before committing changes.
```bash
nargo fmt
```

### Independent Setup

To set up and work with the Nodash library independently:

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/olehmisar/nodash.git # Or your fork
    cd nodash
    ```

2.  **Prerequisites:**
    *   Install [Noir (Nargo)](https://noir-lang.org/docs/getting_started/installation/). Ensure `nargo` is in your system's PATH.

3.  **Build (Optional):**
    To compile the Nodash library itself (e.g., to check for compile errors):
    ```bash
    nargo build 
    # or, to build with debug prints enabled:
    # nargo build --features debug_print
    ```
    (Note: `nargo build` on a library target primarily checks compilation.)

4.  **Run Noir Library Tests:**
    ```bash
    nargo test
    ```

5.  **Run CLI Tests:**
    Ensure the scripts are executable:
    ```bash
    chmod +x nodash_cli.sh
    chmod +x tests/cli/test_cli.sh
    ```
    Then run:
    ```bash
    ./tests/cli/test_cli.sh
    ```

---

*This README is a work in progress and will be updated as the library evolves.*
