#!/bin/bash

# Test script for nodash_cli.sh

# Determine paths relative to this test script's location
TEST_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CLI_SCRIPT="$TEST_SCRIPT_DIR/../../nodash_cli.sh" # Path to nodash_cli.sh in project root

TEST_COUNT=0
PASS_COUNT=0

# Ensure the CLI script exists and is executable
if [ ! -f "$CLI_SCRIPT" ]; then
    echo "FATAL: CLI script $CLI_SCRIPT not found."
    exit 1
fi
if [ ! -x "$CLI_SCRIPT" ]; then
    echo "FATAL: CLI script $CLI_SCRIPT is not executable. Run chmod +x."
    exit 1
fi

# Function to run a test case
# $1: Test description
# $2: Expected exit code
# $3: Expected stdout content (grep pattern)
# $4: Expected stderr content (grep pattern, use "" if none expected, or special "EMPTY" if expecting empty stderr)
# $5+: Command and arguments to run (will be prefixed with CLI_SCRIPT)
run_test() {
    ((TEST_COUNT++))
    local description="$1"
    local expected_exit_code="$2"
    local expected_stdout_pattern="$3"
    local expected_stderr_pattern="$4"
    shift 4
    local command_to_run=("$CLI_SCRIPT" "$@")

    echo -n "Test: $description ... "
    
    TMP_STDOUT=$(mktemp)
    TMP_STDERR=$(mktemp)
    
    # Execute command
    "${command_to_run[@]}" > "$TMP_STDOUT" 2> "$TMP_STDERR"
    local actual_exit_code=$?
    
    local actual_stdout=$(cat "$TMP_STDOUT")
    local actual_stderr=$(cat "$TMP_STDERR")
    rm -f "$TMP_STDOUT" "$TMP_STDERR"

    local test_passed=true
    local failure_messages=""

    if [ "$actual_exit_code" -ne "$expected_exit_code" ]; then
        failure_messages+="  FAIL: Exit code. Expected $expected_exit_code, got $actual_exit_code\n"
        test_passed=false
    fi

    if ! echo "$actual_stdout" | grep -qE "$expected_stdout_pattern"; then
        failure_messages+="  FAIL: STDOUT mismatch.\n"
        failure_messages+="    Expected pattern: $expected_stdout_pattern\n"
        failure_messages+="    Actual STDOUT: $actual_stdout\n"
        test_passed=false
    fi
    
    if [ "$expected_stderr_pattern" == "EMPTY" ]; then
        if [ -n "$actual_stderr" ]; then
            failure_messages+="  FAIL: Expected empty STDERR, but got:\n"
            failure_messages+="    Actual STDERR: $actual_stderr\n"
            test_passed=false
        fi
    elif [ -n "$expected_stderr_pattern" ]; then
        if ! echo "$actual_stderr" | grep -qE "$expected_stderr_pattern"; then
            failure_messages+="  FAIL: STDERR mismatch.\n"
            failure_messages+="    Expected pattern: $expected_stderr_pattern\n"
            failure_messages+="    Actual STDERR: $actual_stderr\n"
            test_passed=false
        fi
    elif [ -n "$actual_stderr" ]; then # If no specific stderr pattern, but stderr is not empty
        failure_messages+="  FAIL: Unexpected STDERR output:\n"
        failure_messages+="    Actual STDERR: $actual_stderr\n"
        test_passed=false
    fi

    if $test_passed; then
        echo "PASS"
        ((PASS_COUNT++))
    else
        echo -e "FAIL\n$failure_messages" # Print FAIL on its own line then messages
    fi
}

echo "Starting Nodash CLI tests..."

# --- General CLI Behavior Tests ---
run_test "CLI: No arguments" 1 "Usage: " "" # Expect usage message on stdout
run_test "CLI: Unknown command" 1 "Error: Unknown command 'foo'" "" # Expect error and usage on stdout

# --- parse_u64 Tests ---
run_test "parse_u64: Valid input" 0 "^12345$" "EMPTY" parse_u64 "12345"
run_test "parse_u64: Invalid format" 0 "^Error: InvalidStringFormat$" "EMPTY" parse_u64 "abc"
run_test "parse_u64: Overflow" 0 "^Error: NumericOverflow$" "EMPTY" parse_u64 "18446744073709551616"
run_test "parse_u64: Missing argument" 1 "Usage: " "" parse_u64

# --- parse_u128 Tests ---
run_test "parse_u128: Valid input" 0 "^12345678901234567890$" "EMPTY" parse_u128 "12345678901234567890"
run_test "parse_u128: Invalid format" 0 "^Error: InvalidStringFormat$" "EMPTY" parse_u128 "123x"
run_test "parse_u128: Overflow" 0 "^Error: NumericOverflow$" "EMPTY" parse_u128 "340282366920938463463374607431768211456" # u128_max + 1

# --- hex_to_u128 Tests ---
run_test "hex_to_u128: Valid input (max)" 0 "^340282366920938463463374607431768211455$" "EMPTY" hex_to_u128 "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
run_test "hex_to_u128: Invalid format" 0 "^Error: InvalidStringFormat$" "EMPTY" hex_to_u128 "FG"
# This specific overflow case was identified as tricky for hex_to_u128 due to fixed length input
# The harness's try_hex_str_to_u128 should catch this during accumulation.
run_test "hex_to_u128: Overflow during accumulation" 0 "^Error: NumericOverflow$" "EMPTY" hex_to_u128 "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA" 

# --- field_to_hex Tests ---
run_test "field_to_hex: Valid input" 0 "^000000000000000000000000000000000000000000000000000000000000007b$" "EMPTY" field_to_hex "123"
run_test "field_to_hex: Zero input" 0 "^0000000000000000000000000000000000000000000000000000000000000000$" "EMPTY" field_to_hex "0"

# --- bytes_to_hex Tests ---
run_test "bytes_to_hex: Valid input" 0 "^0a14ff$" "EMPTY" bytes_to_hex "10,20,255"
run_test "bytes_to_hex: Single byte" 0 "^07$" "EMPTY" bytes_to_hex "7"
run_test "bytes_to_hex: Empty CSV" 0 "^$" "EMPTY" bytes_to_hex "" 
# Test harness parse_u8_csv_to_bounded_vec clamps u8 values > 255 to 255
run_test "bytes_to_hex: CSV value > 255 (clamps to FF)" 0 "^ff$" "EMPTY" bytes_to_hex "300"

# --- hex_to_bytes Tests ---
# Harness specific logic for hex_to_bytes: only fixed lengths (2, 4, 64) are directly supported for now.
run_test "hex_to_bytes: Valid input (6 chars)" 0 "^222,173,191$" "EMPTY" hex_to_bytes "deadbf"
run_test "hex_to_bytes: Empty input" 0 "^$" "EMPTY" hex_to_bytes ""
run_test "hex_to_bytes: Invalid format" 0 "^Error: InvalidStringFormat$" "EMPTY" hex_to_bytes "0a1x" # Length 4
run_test "hex_to_bytes: Odd length (CLI error)" 0 "^Error:HexStringMustHaveEvenLength$" "EMPTY" hex_to_bytes "abc"

# --- keccak256_bytes Tests ---
run_test "keccak256_bytes: Empty input" 0 "^c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470$" "EMPTY" keccak256_bytes ""
run_test "keccak256_bytes: Valid input" 0 "^080208cb333552056104003e862179229011094999dd31739627760def71fa09$" "EMPTY" keccak256_bytes "1,2,3" # Hash of [1,2,3]

# --- sha256_bytes Tests ---
# SHA256 of empty string: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
run_test "sha256_bytes: Empty input" 0 "^e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855$" "EMPTY" sha256_bytes ""
# SHA256 of [1,2,3]: 039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81
run_test "sha256_bytes: Valid input" 0 "^039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81$" "EMPTY" sha256_bytes "1,2,3"

# --- parse_bool Tests ---
run_test "parse_bool: 'true'" 0 "^true$" "EMPTY" parse_bool "true"
run_test "parse_bool: 'FALSE'" 0 "^false$" "EMPTY" parse_bool "FALSE"
run_test "parse_bool: '1'" 0 "^true$" "EMPTY" parse_bool "1"
run_test "parse_bool: Invalid 'T'" 0 "^Error: InvalidBooleanString$" "EMPTY" parse_bool "T"
run_test "parse_bool: Invalid 'truth'" 0 "^Error: InvalidBooleanString$" "EMPTY" parse_bool "truth"

# --- div_ceil Tests ---
run_test "div_ceil: Valid" 0 "^4$" "EMPTY" div_ceil "10" "3"
run_test "div_ceil: Division by zero" 0 "^Error: DivisionByZero$" "EMPTY" div_ceil "10" "0"
run_test "div_ceil: Missing one argument" 1 "Usage: " "" div_ceil "10"
run_test "div_ceil: Missing all arguments" 1 "Usage: " "" div_ceil

# --- Summary ---
echo ""
echo "CLI Test Summary: $PASS_COUNT / $TEST_COUNT tests passed."

if [ "$PASS_COUNT" -ne "$TEST_COUNT" ]; then
    exit 1
else
    exit 0
fi
