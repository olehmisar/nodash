// src/error.nr
pub enum Error {
    // String parsing errors
    InvalidStringFormat, // e.g. non-digit in number string, non-hex in hex string, invalid bool string
    NumericOverflow,     // Parsed number exceeds target type's capacity (e.g. for u128)

    // Conversion errors (for TryFrom)
    ValueOutOfBounds,    // Input value cannot fit into target type
}

// Optional: A helper to convert Error to a string for debugging, if useful.
// Not strictly necessary for this refactor's goal.
// impl Error {
//     pub fn to_str(self) -> str<30> { // Max length needs adjustment
//         match self {
//             Error::InvalidStringFormat => "Error: InvalidStringFormat",
//             Error::NumericOverflow => "Error: NumericOverflow",
//             Error::ValueOutOfBounds => "Error: ValueOutOfBounds",
//         }
//     }
// }
