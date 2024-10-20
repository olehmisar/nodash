# Nodash - Lodash for Noir

Nodash is a utility library for [Noir](https://github.com/noir-lang/noir) language.

## Installation

Put this into your Nargo.toml.

If you are using Noir:

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "v0.35.1" }
```

If you are using Aztec:

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "aztec-v0.55.0" }
```

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
fn to_hex_string_bytes(value: Field) -> [u8; 64]
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
