// src/debug.nr

/// Prints a Field value with a label if the "debug_print" feature is enabled.
/// Does nothing otherwise.
#[cfg(feature = "debug_print")]
pub fn print_field(label: str<20>, value: Field) {
    std::println(label);
    std::println(value);
}

#[cfg(not(feature = "debug_print"))]
pub fn print_field(_label: str<20>, _value: Field) {
    // This function is a no-op when "debug_print" is not enabled.
}

/// Prints a u64 value with a label if the "debug_print" feature is enabled.
/// Does nothing otherwise.
#[cfg(feature = "debug_print")]
pub fn print_u64(label: str<20>, value: u64) {
    std::println(label);
    std::println(value);
}

#[cfg(not(feature = "debug_print"))]
pub fn print_u64(_label: str<20>, _value: u64) {
    // No-op
}

/// Prints a u128 value with a label if the "debug_print" feature is enabled.
/// Does nothing otherwise.
#[cfg(feature = "debug_print")]
pub fn print_u128(label: str<20>, value: u128) {
    std::println(label);
    std::println(value);
}

#[cfg(not(feature = "debug_print"))]
pub fn print_u128(_label: str<20>, _value: u128) {
    // No-op
}

/// Prints a boolean value with a label if the "debug_print" feature is enabled.
/// Does nothing otherwise.
#[cfg(feature = "debug_print")]
pub fn print_bool(label: str<20>, value: bool) {
    std::println(label);
    if value {
        std::println("true");
    } else {
        std::println("false");
    }
}

#[cfg(not(feature = "debug_print"))]
pub fn print_bool(_label: str<20>, _value: bool) {
    // No-op
}

/// Prints a string slice with a label if the "debug_print" feature is enabled.
/// Does nothing otherwise.
#[cfg(feature = "debug_print")]
pub fn print_str<let N: u32>(label: str<20>, value: str<N>) {
    std::println(label);
    std::println(value);
}

#[cfg(not(feature = "debug_print"))]
pub fn print_str<let N: u32>(_label: str<20>, _value: str<N>) {
    // No-op
}
