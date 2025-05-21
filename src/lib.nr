mod convert;
mod hash;
mod math;
pub mod solidity;
mod string;
mod tables;
mod array;
mod validate_inputs;
mod error; 
mod debug; // Add new debug module

pub use array::pack_bytes;
pub use convert::TryFrom; // TryFrom trait might change
pub use error::Error; // Export the Error enum
pub use hash::{keccak256, pedersen, poseidon2, sha256};
pub use math::{clamp, div_ceil, sqrt::sqrt};
pub use string::{field_to_hex, ord, str_to_u64, to_hex_string_bytes};
pub use validate_inputs::{validate_inputs, ValidateInput};

pub trait ArrayExtensions<T, let N: u32> {
    fn slice<let L: u32>(self, start: u32) -> [T; L];
    fn try_slice<let L: u32>(self, start: u32) -> Option<[T; L]>; // New
    fn pad_start<let M: u32>(self, pad_value: T) -> [T; M];
    fn pad_end<let M: u32>(self, pad_value: T) -> [T; M];
    fn enumerate(self) -> [(u32, T); N];
    fn contains(self, value: T) -> bool where T: Eq;
    fn reverse(self) -> [T; N];
}

// Export debug utilities (they are no-ops if feature "debug_print" is not enabled)
pub use debug::{print_field, print_u64, print_u128, print_bool, print_str};
