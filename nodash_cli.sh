#!/bin/bash

# Nodash CLI Wrapper Script

# Nodash CLI Wrapper Script

echo ""
echo ' ____    ____    _____    ____    ____    __  __   ____  '
echo '|    \  |    \  /     \  |    \  |    \  |  ||  | /    \ '
echo '|  o  ) |  o  )|  o  |  ||  _  | |  _  | |  ||  ||  o  | '
echo '|     | |     ||     |  ||  |  | |  |  | |  ||  ||     | '
echo '|  O  | |  O  ||  |  |  ||  |  | |  |  | |  ||  ||  |  | '
echo '|     | |     ||  |  |  ||  |  | |  |  | |  ||  ||  |  | '
echo '|_____| |_____| \_____/  |__|__| |__|__|  \____/  \____/ '
echo ""
echo "                Nodash CLI - Your Noir Utility Belt!"
echo ""

# Determine the script's own directory to make paths relative to the script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Path to the Noir harness project and other key files relative to the script's location
HARNESS_DIR="$SCRIPT_DIR/tests/nodash_cli_harness"
HARNESS_PROVER_TOML="$HARNESS_DIR/Prover.toml"
ROOT_NARGO_TOML="$SCRIPT_DIR/Nargo.toml" # Main Nargo.toml of the nodash project

# Ensure script is in a valid nodash project structure
if [ ! -f "$ROOT_NARGO_TOML" ]; then
    echo "Error: Nodash project Nargo.toml not found at $ROOT_NARGO_TOML. Ensure the script is in the nodash project root."
    exit 1
fi
if [ ! -d "$HARNESS_DIR" ]; then
    echo "Error: CLI harness directory not found at $HARNESS_DIR."
    exit 1
fi

# Ensure nargo is installed and accessible
if ! command -v nargo &> /dev/null; then
    echo "Error: nargo command could not be found. Please ensure Noir is installed and in your PATH."
    exit 1
fi

# --- Helper Functions ---
function print_usage {
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Available commands:"
    echo "  parse_u64 <string_value>              Parses a decimal string to u64."
    echo "  parse_u128 <string_value>             Parses a decimal string to u128."
    echo "  hex_to_u128 <hex_string_value>        Parses a hex string (no 0x) to u128."
    echo "  field_to_hex <field_dec_string>       Converts a decimal Field string to hex."
    echo "  bytes_to_hex <u8_csv_string>          Converts comma-separated u8 decimal values to hex."
    echo "                                          Example: $0 bytes_to_hex \"10,20,255\""
    echo "  hex_to_bytes <hex_string>             Converts a hex string to comma-separated u8 decimals."
    echo "                                          Example: $0 hex_to_bytes \"deadbf\" (max 64 hex chars for this CLI)"
    echo "  keccak256_bytes <u8_csv_string>       Hashes comma-separated u8 values with Keccak256."
    echo "  sha256_bytes <u8_csv_string>          Hashes comma-separated u8 values with SHA256."
    echo "  parse_bool <string_value>             Parses 'true', 'false', '1', '0' to boolean."
    echo "  div_ceil <num_a_u64> <num_b_u64>      Calculates ceil(num_a / num_b) for u64."
    echo ""
    echo "Notes:"
    echo " - Hex strings should not include the '0x' prefix for parsing commands."
    echo " - CSV strings should be quoted if they contain spaces, e.g., \"10, 20, 30\"."
}

function execute_nodash_harness {
    local command="$1"
    local arg1="$2"
    local arg2="$3"

    # Prepare Prover.toml
    # Note: String arguments for Noir main function must be padded with nulls to their fixed str<N> length
    # The harness main.nr expects str<20> for command, str<1024> for arg1, str<1024> for arg2.
    # However, nargo auto-pads string literals from Prover.toml if they are shorter than schema.
    # For simplicity, we are using fixed large string sizes in harness main.nr
    # and will rely on nargo's behavior or ensure strings are not excessively long for CLI.

    # The harness main.nr uses str<MAX_CSV_STR_LEN_CLI> for arg1_str and str<U64_STR_LEN> for arg2_str
    # MAX_CSV_STR_LEN_CLI = 256 * 4 = 1024
    # U64_STR_LEN = 20
    # command is str<20>

    cat > "$HARNESS_PROVER_TOML" <<- EOM
command = "$command"
arg1_str = "$arg1"
arg2_str = "$arg2"
EOM

    # Execute nargo
    # stderr is redirected to stdout to capture all output from nargo, including panics/asserts
    if output=$(cd "$HARNESS_DIR" && nargo execute cli_witness 2>&1); then
        # Try to parse structured output
        if [[ "$output" == *"RESULT:"* ]]; then
            echo "$output" | sed -n 's/RESULT:\(.*\)/\1/p' # Extract line after RESULT:
            # If there are multiple lines after RESULT:, sed will print them all.
            # For single line result: echo "$output" | grep "RESULT:" | cut -d':' -f2-
        elif [[ "$output" == *"ERROR_TYPE:"* ]]; then
            error_type=$(echo "$output" | grep "ERROR_TYPE:" | cut -d':' -f2-)
            echo "Error: $error_type"
        elif [[ "$output" == *"ERROR:"* ]]; then # Generic error from harness
            error_msg=$(echo "$output" | grep "ERROR:" | cut -d':' -f2-)
            echo "Error: $error_msg"
        else # Fallback for unexpected output or if nargo execute failed before harness could print
            echo "Execution failed or output format unexpected:"
            echo "$output"
        fi
    else
        echo "Nargo execution failed. Output:"
        echo "$output"
    fi

    # Clean up Prover.toml
    # rm -f "$HARNESS_PROVER_TOML" # Optional: keep for debugging
}


# --- Main Script Logic ---
if [ "$#" -lt 1 ]; then
    print_usage
    exit 1
fi

SUBCOMMAND="$1"
shift # Remove subcommand from argument list

case "$SUBCOMMAND" in
    parse_u64)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 parse_u64 <string_value>"; exit 1; fi
        execute_nodash_harness "parse_u64" "$1" ""
        ;;
    parse_u128)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 parse_u128 <string_value>"; exit 1; fi
        execute_nodash_harness "parse_u128" "$1" ""
        ;;
    hex_to_u128)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 hex_to_u128 <hex_string_value>"; exit 1; fi
        execute_nodash_harness "hex_to_u128" "$1" ""
        ;;
    field_to_hex)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 field_to_hex <field_dec_string>"; exit 1; fi
        execute_nodash_harness "field_to_hex" "$1" ""
        ;;
    bytes_to_hex)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 bytes_to_hex <u8_csv_string>"; exit 1; fi
        execute_nodash_harness "bytes_to_hex" "$1" ""
        ;;
    hex_to_bytes)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 hex_to_bytes <hex_string>"; exit 1; fi
        execute_nodash_harness "hex_to_bytes" "$1" ""
        ;;
    keccak256_bytes)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 keccak256_bytes <u8_csv_string>"; exit 1; fi
        execute_nodash_harness "keccak256_bytes" "$1" ""
        ;;
    sha256_bytes)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 sha256_bytes <u8_csv_string>"; exit 1; fi
        execute_nodash_harness "sha256_bytes" "$1" ""
        ;;
    parse_bool)
        if [ "$#" -ne 1 ]; then echo "Usage: $0 parse_bool <string_value>"; exit 1; fi
        execute_nodash_harness "parse_bool" "$1" ""
        ;;
    div_ceil)
        if [ "$#" -ne 2 ]; then echo "Usage: $0 div_ceil <num_a_u64> <num_b_u64>"; exit 1; fi
        execute_nodash_harness "div_ceil" "$1" "$2"
        ;;
    *)
        echo "Error: Unknown command '$SUBCOMMAND'"
        print_usage
        exit 1
        ;;
esac

exit 0
