# Nodash - Lodash for Noir

Nodash is a utility library for [Noir](https://github.com/noir-lang/noir) language.

## Installation

Put this into your Nargo.toml.

If you are using Noir:

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "v0.35.1" }
```

The version of nodash matches the version of Noir. The patch version may be different if a bugfix or a new feature is added for the same version of Noir. E.g., nodash@v0.35.0 and nodash@v0.35.1 are compatible with noir@v0.35.0.

---

If you are using Aztec:

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "aztec-v0.57.0" }
```

The version of nodash matches the version of Aztec. E.g., nodash@aztec-v0.57.0 is compatible with aztec@v0.57.0.

## Docs

### `sqrt`

```rs
use nodash::sqrt;

assert(sqrt(4 as u64) == 2);

// it floors the result
assert(sqrt(8 as u64) == 2);
```

### `clamp`

```rs
use nodash::clamp;

// if too small, return min
assert(clamp(1 as u64, 2 as u64, 3 as u64) == 2 as u64);
// if too big, return max
assert(clamp(4 as u64, 1 as u64, 3 as u64) == 3 as u64);
// if in range, return value
assert(clamp(2 as u64, 1 as u64, 3 as u64) == 2 as u64);
```

### `div_ceil`

Calculates `a / b` rounded up to the nearest integer.

```rs
use nodash::div_ceil;

assert(div_ceil(10 as u64, 3) == 4);
```

### `solidity::encode_with_selector`

Equivalent to `abi.encodeWithSelector` in Solidity.

```rs
use nodash::solidity::encode_with_selector;

let selector: u32 = 0xa9059cbb; // transfer(address,uint256)
let args: [Field; 2] = [
  0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, // address
  123 // uint256
];
let encoded = encode_with_selector(selector, args);
// typeof encoded: [u8; 68]
```

### `to_hex_string_bytes`

Converts a `Field` to a hex string.

```rs
let my_hash = 0x0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf;
let expected = "0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf";
assert_eq(to_hex_string_bytes(my_hash), expected.as_bytes());
```

### `str_to_u64`

Converts a string to a `u64`.

```rs
use nodash::str_to_u64;

assert(str_to_u64("02345678912345678912") == 02345678912345678912);
```

### `array_concat`

Concatenates two arrays.

```rs
use nodash::array_concat;

assert(array_concat([1, 2, 3], [4, 5]) == [1, 2, 3, 4, 5]);
```
