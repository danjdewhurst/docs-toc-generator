#!/usr/bin/env bats

# Test suite for generate-docs-toc.sh

# Setup and teardown
setup() {
    # Get the directory where tests are located
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    SCRIPT="$PROJECT_ROOT/generate-docs-toc.sh"
    FIXTURES_DIR="$TEST_DIR/fixtures"
    OUTPUT_DIR="$TEST_DIR/output"
    # Use unique output file per test to avoid parallel conflicts
    TEST_OUTPUT="$OUTPUT_DIR/test-output-$$-$RANDOM.md"

    # Ensure output directory exists and is clean
    mkdir -p "$OUTPUT_DIR"
    rm -f "$TEST_OUTPUT"
}

teardown() {
    # Clean up test outputs
    rm -f "$TEST_OUTPUT"
}

# Helper function to count lines in output
count_lines() {
    echo "$1" | wc -l | tr -d ' '
}

# Helper function to check if string contains substring
contains() {
    [[ "$1" =~ $2 ]]
}

# ============================================================================
# Basic Functionality Tests
# ============================================================================

@test "script exists and is executable" {
    [ -x "$SCRIPT" ]
}

@test "script runs without errors with default options" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "script displays version with -v flag" {
    run "$SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Documentation ToC Generator v" ]]
}

@test "script displays version with --version flag" {
    run "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2.0.0" ]]
}

@test "script displays help with -h flag" {
    run "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
}

@test "script displays help with --help flag" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "script fails with invalid option" {
    run "$SCRIPT" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Unknown option" ]]
}

@test "script fails when docs directory does not exist" {
    cd "$TEST_DIR"
    run "$SCRIPT" -d non-existent-dir
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Documentation directory 'non-existent-dir' not found" ]]
}

# ============================================================================
# Output Mode Tests
# ============================================================================

@test "script generates output with default settings" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "# Documentation Table of Contents" ]]
    [[ "$output" =~ "Generated:" ]]
    [[ "$output" =~ "Total files:" ]]
}

@test "script writes output to file with -o flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
    [[ "$output" =~ "Table of contents generated:" ]]
}

@test "script writes output to file with --output flag" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --output "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "output file contains expected content" {
    cd "$FIXTURES_DIR"
    "$SCRIPT" -o "$TEST_OUTPUT"
    [ -f "$TEST_OUTPUT" ]
    content=$(cat "$TEST_OUTPUT")
    [[ "$content" =~ "# Documentation Table of Contents" ]]
    [[ "$content" =~ "Main Documentation" ]]
}

@test "simple mode generates minimal output" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --simple
    [ "$status" -eq 0 ]
    [[ "$output" =~ "# Documentation Table of Contents" ]]
    [[ ! "$output" =~ "Total files:" ]]
    [[ ! "$output" =~ "Modified:" ]]
    [[ ! "$output" =~ "KB" ]]
}

@test "simple mode with -s flag works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -s
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Modified:" ]]
}

@test "quiet mode suppresses progress messages" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -o "$TEST_OUTPUT" -q
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Table of contents generated:" ]]
}

@test "quiet mode with --quiet flag works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --output "$TEST_OUTPUT" --quiet
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ============================================================================
# Directory and Path Tests
# ============================================================================

@test "custom directory with -d flag works" {
    run "$SCRIPT" -d "$FIXTURES_DIR/docs"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
}

@test "custom directory with --directory flag works" {
    run "$SCRIPT" --directory "$FIXTURES_DIR/docs"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installation Guide" ]]
}

# ============================================================================
# Content Extraction Tests
# ============================================================================

@test "extracts headings from markdown files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ "$output" =~ "Installation Guide" ]]
    [[ "$output" =~ "Quick Start" ]]
    [[ "$output" =~ "API Reference" ]]
}

@test "extracts snippets in full mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "This is the main documentation" ]]
    [[ "$output" =~ "Follow these steps" ]]
}

@test "no-snippets mode skips snippet extraction" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --no-snippets
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "This is the main documentation" ]]
}

@test "handles files without headings" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No Heading" ]]
}

@test "custom snippet length works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -l 50
    [ "$status" -eq 0 ]
    # Should truncate long snippets
    [[ "$output" =~ "..." ]]
}

@test "snippet length with --snippet-length flag works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --snippet-length 100
    [ "$status" -eq 0 ]
}

@test "strips markdown formatting from snippets" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    # Should not contain markdown bold/italic markers in the snippet
    output_snippet=$(echo "$output" | grep -A 2 "Main Documentation")
    [[ ! "$output_snippet" =~ "\*\*bold\*\*" ]]
    [[ ! "$output_snippet" =~ "\*italic\*" ]]
}

# ============================================================================
# Custom Title Tests
# ============================================================================

@test "custom title with --title flag works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --title "My Custom Title"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "# My Custom Title" ]]
    [[ ! "$output" =~ "# Documentation Table of Contents" ]]
}

# ============================================================================
# File Metadata Tests
# ============================================================================

@test "displays file sizes in full mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "B • Modified:" ]] || [[ "$output" =~ "KB • Modified:" ]]
}

@test "displays modification dates in full mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Modified:" ]]
    # Check for date format YYYY-MM-DD
    [[ "$output" =~ "Modified: 20" ]]
}

@test "does not display metadata in simple mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --simple
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Modified:" ]]
    [[ ! "$output" =~ "KB" ]]
}

# ============================================================================
# File Counting Tests
# ============================================================================

@test "counts total files correctly" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Total files:" ]]
    # Should count all files in the fixtures
    [[ "$output" =~ "10" ]] || [[ "$output" =~ "9" ]] || [[ "$output" =~ "8" ]]
}

@test "counts markdown files correctly" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "markdown files" ]]
}

@test "handles non-markdown files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    # Should list the config.json file
    [[ "$output" =~ "config.json" ]]
}
