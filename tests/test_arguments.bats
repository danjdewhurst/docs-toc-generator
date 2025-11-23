#!/usr/bin/env bats

# Test suite for command-line argument parsing

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    SCRIPT="$PROJECT_ROOT/generate-docs-toc.sh"
    FIXTURES_DIR="$TEST_DIR/fixtures"
    OUTPUT_DIR="$TEST_DIR/output"
    # Use unique output file per test to avoid parallel conflicts
    TEST_OUTPUT="$OUTPUT_DIR/test-output-$$-$RANDOM.md"

    mkdir -p "$OUTPUT_DIR"
    rm -f "$TEST_OUTPUT"
}

teardown() {
    rm -f "$TEST_OUTPUT"
}

# ============================================================================
# Argument Parsing Tests
# ============================================================================

@test "accepts -d with directory path" {
    run "$SCRIPT" -d "$FIXTURES_DIR/docs"
    [ "$status" -eq 0 ]
}

@test "accepts --directory with directory path" {
    run "$SCRIPT" --directory "$FIXTURES_DIR/docs"
    [ "$status" -eq 0 ]
}

@test "accepts -o with file path" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "accepts --output with file path" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --output "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "accepts -s flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -s
    [ "$status" -eq 0 ]
}

@test "accepts --simple flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --simple
    [ "$status" -eq 0 ]
}

@test "accepts -l with number" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -l 150
    [ "$status" -eq 0 ]
}

@test "accepts --snippet-length with number" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --snippet-length 150
    [ "$status" -eq 0 ]
}

@test "accepts --max-depth with number" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --max-depth 2
    [ "$status" -eq 0 ]
}

@test "accepts --sort with valid values" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort name
    [ "$status" -eq 0 ]

    run "$SCRIPT" --sort date
    [ "$status" -eq 0 ]

    run "$SCRIPT" --sort size
    [ "$status" -eq 0 ]
}

@test "rejects --sort with invalid value" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort invalid
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: --sort must be 'name', 'date', or 'size'" ]]
}

@test "accepts -e with pattern" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "*.draft.md"
    [ "$status" -eq 0 ]
}

@test "accepts --exclude with pattern" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --exclude "DRAFT.md"
    [ "$status" -eq 0 ]
}

@test "accepts multiple -e flags" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "*.draft.md" -e "tmp/" -e "archive/"
    [ "$status" -eq 0 ]
}

@test "accepts -i with pattern" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md"
    [ "$status" -eq 0 ]
}

@test "accepts --include with pattern" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --include "*.md"
    [ "$status" -eq 0 ]
}

@test "accepts multiple -i flags" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" -i "*.txt"
    [ "$status" -eq 0 ]
}

@test "accepts --no-snippets flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --no-snippets
    [ "$status" -eq 0 ]
}

@test "accepts --title with custom text" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --title "My Documentation"
    [ "$status" -eq 0 ]
}

@test "accepts --group-by with valid values" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory
    [ "$status" -eq 0 ]

    run "$SCRIPT" --group-by type
    [ "$status" -eq 0 ]

    run "$SCRIPT" --group-by none
    [ "$status" -eq 0 ]
}

@test "rejects --group-by with invalid value" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by invalid
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: --group-by must be 'directory', 'type', or 'none'" ]]
}

@test "accepts -q flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$TEST_OUTPUT" -q
    [ "$status" -eq 0 ]
}

@test "accepts --quiet flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$TEST_OUTPUT" --quiet
    [ "$status" -eq 0 ]
}

# ============================================================================
# Combined Arguments Tests
# ============================================================================

@test "accepts multiple flags combined" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -d docs -o "$TEST_OUTPUT" -s -q
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "accepts long form arguments combined" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --directory docs --output "$TEST_OUTPUT" --simple --quiet
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "accepts mixed short and long form arguments" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -d docs --output "$TEST_OUTPUT" -s --quiet
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "accepts all options together" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -d docs -o "$TEST_OUTPUT" -l 100 --max-depth 2 --sort name -e "DRAFT.md" --no-snippets --title "Test" --group-by directory -q
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "handles empty directory path gracefully" {
    run "$SCRIPT" -d ""
    [ "$status" -eq 1 ]
}

@test "handles directory with spaces in name" {
    mkdir -p "$OUTPUT_DIR/test dir with spaces"
    touch "$OUTPUT_DIR/test dir with spaces/test.md"
    run "$SCRIPT" -d "$OUTPUT_DIR/test dir with spaces"
    [ "$status" -eq 0 ]
    rm -rf "$OUTPUT_DIR/test dir with spaces"
}

@test "handles output file with spaces in name" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$OUTPUT_DIR/test output file.md"
    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_DIR/test output file.md" ]
    rm -f "$OUTPUT_DIR/test output file.md"
}

@test "handles title with special characters" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --title "Documentation & API Reference (2024)"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Documentation & API Reference (2024)" ]]
}
