# Nodash - Lodash for Noir

Nodash is a utility library for [Noir](https://github.com/noir-lang/noir) language.

## Installation

Put this into your Nargo.toml.

```toml
nodash = { git = "https://github.com/olehmisar/nodash/", tag = "v0.42.0" }
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

Calculates `a / b` rounded up to the nearest integer.

```rs
use nodash::div_ceil;

assert(div_ceil(10 as u64, 3) == 4);
```

### Hashes

Hash functions can either accept a `[T; N]` or a `BoundedVec<T, N>` (if technically possible).

#### `poseidon2`

```rs
use nodash::poseidon2;

// hashes the whole array
let hash = poseidon2([10, 20]);
// hashes elements up to the length (in this case, 2)
let hash = poseidon2(BoundedVec::from_parts([10, 20, 0], 2));
```

#### `pedersen`

```rs
use nodash::pedersen;

let hash = pedersen([10, 20]);
```

#### `sha256`

sha256 is expensive to compute in Noir, so use [poseidon2](#poseidon2) where possible.

```rs
use nodash::sha256;

let hash = sha256([10, 20]);
// or
let hash = sha256(BoundedVec::from_parts([10, 20, 0], 2));
```

#### `keccak256`

keccak256 is expensive to compute in Noir, so use [poseidon2](#poseidon2) where possible.

```rs
use nodash::keccak256;

let hash = keccak256([10, 20]);
// or
let hash = keccak256(BoundedVec::from_parts([10, 20, 0], 2));
```

#### Partial SHA256

Similar to partial [`sha256`](https://github.com/noir-lang/sha256) but supports `BoundedVec<u8, N>` and `[u8; N]` as input.

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

### `field_to_hex`

Converts a `Field` to a hex string (without `0x` prefix).

```rs
let my_hash = 0x0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf;
let expected = "0d67824fead966192029093a3aa5c719f2b80262c4f14a5c97c5d70e4b27f2bf";
assert_eq(field_to_hex(my_hash), expected);
```

### `str_to_u64`

Converts a string to a `u64`.

```rs
use nodash::str_to_u64;

assert(str_to_u64("02345678912345678912") == 02345678912345678912);
```

### `try_from`

Fail-able conversion.

```rs
use nodash::TryFrom;

assert(u8::try_from(123) == 123);
u8::try_from(256); // runtime error

assert(u128::try_from(123) == 123);
```

### `ord`

Returns the ASCII code of a single character.

```rs
use nodash::ord;

assert(ord("a") == 97);
```

### `ArrayExtensions`

#### `slice<L>(start: u32) -> [T; L]`

Returns a slice of the array, starting at `start` and ending at `start + L`. Panics if `start + L` is out of bounds.

```rs
use nodash::ArrayExtensions;

assert([1, 2, 3, 4, 5].slice::<3>(1) == [2, 3, 4]);
```

#### `pad_start`

Pads the start of the array with a value.

```rs
use nodash::ArrayExtensions;

assert([1, 2, 3].pad_start::<5>(0) == [0, 0, 1, 2, 3]);
```

#### `pad_end`

Pads the end of the array with a value.

```rs
use nodash::ArrayExtensions;

assert([1, 2, 3].pad_end::<5>(0) == [1, 2, 3, 0, 0]);
```

#### `enumerate`

Returns an array of tuples, where each tuple contains the index and the value of the array element.

```rs
use nodash::ArrayExtensions;

assert(["a", "b", "c"].enumerate() == [(0, "a"), (1, "b"), (2, "c")]);
```

### `pack_bytes`

Packs `[u8; N]` into `[Field; N / 31 + 1]`. Useful, if you need to get a hash over bytes. I.e., `nodash::poseidon2(nodash::pack_bytes(bytes))` will be MUCH cheaper than `nodash::poseidon2(bytes)`.

```rs
use nodash::pack_bytes;

let bytes: [u8; 32] = [0; 32];
let packed = pack_bytes(bytes);
```

### Validate `main` function inputs

`fn main` inputs are not validated by Noir. For example, you have a `U120` struct like this:

```rs
struct U120 {
    inner: Field,
}

impl U120 {
    fn new(inner: Field) -> Self {
        inner.assert_max_bit_size::<120>();
        Self { inner }
    }
}
```

You then can create instances of `U120` with `U120::new(123)`. If you pass a value that is larger than 2^120 to `U120::new`, you will get a runtime error because we assert the max bit size of `Field` in `U120::new`.

However, Noir does not check the validity of `U120` fields when passed to a `fn main` function. For example, for this circuit

```rs
fn main(a: U120) {
    // do something with a
}
```

...you can pass any arbitrary value to `a` from JavaScript and it will NOT fail in Noir when `main` is executed:

```js
// this succeeds but it shouldn't!
await noir.execute({
  a: {
    inner: 2n ** 120n + 1n,
  },
});
```

To fix this, you can use the `validate_inputs` attribute on the `main` function:

```rs
use nodash::{validate_inputs, ValidateInput};

// this attribute checks that `U120` is within the range via `ValidateInput` trait
#[validate_inputs]
fn main(a: U120) {
    // do something with a
}

impl ValidateInput for U120 {
    fn validate(self) {
        // call the `new` function that asserts the max bit size
        U120::new(self.inner);
    }
}
```

Now, if you pass a value that is larger than 2^120 to `a` in JavaScript, you will get a runtime error:

```js
// runtime error: "Assertion failed: call to assert_max_bit_size"
await noir.execute({
  a: {
    inner: 2n ** 120n + 1n,
  },
});
```
