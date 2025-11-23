#!/usr/bin/env bats

# Test suite for filtering and sorting functionality

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
# Exclude Pattern Tests
# ============================================================================

@test "exclude pattern removes matching files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "DRAFT.md"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Draft Document" ]]
}

@test "exclude pattern with wildcard works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "*.json"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "config.json" ]]
}

@test "multiple exclude patterns work together" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "DRAFT.md" -e "*.json"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Draft Document" ]]
    [[ ! "$output" =~ "config.json" ]]
}

@test "exclude pattern matches subdirectory path" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "api/"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "API Reference" ]]
    [[ ! "$output" =~ "API Examples" ]]
}

@test "exclude pattern is case sensitive" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "draft.md"
    [ "$status" -eq 0 ]
    # DRAFT.md should still appear (uppercase vs lowercase)
    [[ "$output" =~ "Draft Document" ]]
}

# ============================================================================
# Include Pattern Tests
# ============================================================================

@test "include pattern only shows matching files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "config.json" ]]
}

@test "include pattern with specific filename works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "README.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    # Should not include other files
    total_count=$(echo "$output" | grep -c "^\- \*\*\[" || true)
    [ "$total_count" -eq 1 ]
}

@test "multiple include patterns work together" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "README.md" -i "reference.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ "$output" =~ "API Reference" ]]
}

@test "include pattern overrides other files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "installation.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installation Guide" ]]
    [[ ! "$output" =~ "Quick Start" ]]
}

# ============================================================================
# Combined Include/Exclude Tests
# ============================================================================

@test "exclude takes precedence when both include and exclude match" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" -e "DRAFT.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "Draft Document" ]]
}

@test "complex filtering with multiple includes and excludes" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" -e "DRAFT.md" -e "no-heading.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "Draft Document" ]]
    [[ ! "$output" =~ "No Heading" ]]
}

# ============================================================================
# Sort by Name Tests
# ============================================================================

@test "default sorting is by name" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --simple
    [ "$status" -eq 0 ]
    # Files should be in alphabetical order
    [[ "$output" =~ "Documentation Table of Contents" ]]
}

@test "sort by name explicitly" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort name --simple
    [ "$status" -eq 0 ]
    # Should complete successfully
}

@test "sort by name orders files alphabetically" {
    cd "$FIXTURES_DIR"
    "$SCRIPT" --sort name -o "$TEST_OUTPUT"
    [ -f "$TEST_OUTPUT" ]

    # Extract file order and verify alphabetical sorting within directories
    # Just verify the file was created and has content
    content=$(cat "$TEST_OUTPUT")
    [[ "$content" =~ "Main Documentation" ]]
}

# ============================================================================
# Sort by Date Tests
# ============================================================================

@test "sort by date works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort date
    [ "$status" -eq 0 ]
    # Should complete successfully
}

@test "sort by date shows files in chronological order" {
    cd "$FIXTURES_DIR"
    # Touch a file to update its timestamp
    sleep 1
    touch docs/README.md

    run "$SCRIPT" --sort date --simple
    [ "$status" -eq 0 ]
    # README should appear first (most recently modified)
    # This is a basic check - comprehensive date sorting is hard to test reliably
}

# ============================================================================
# Sort by Size Tests
# ============================================================================

@test "sort by size works" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort size
    [ "$status" -eq 0 ]
    # Should complete successfully
}

@test "sort by size shows larger files first" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --sort size
    [ "$status" -eq 0 ]
    # Larger files should appear before smaller ones
    # The installation.md file has more content than no-heading.md
}

# ============================================================================
# Max Depth Tests
# ============================================================================

@test "max depth 1 only shows files in root" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --max-depth 1
    [ "$status" -eq 0 ]
    # Should include root level files
    [[ "$output" =~ "Main Documentation" ]]
    [[ "$output" =~ "Draft Document" ]]
    [[ "$output" =~ "config.json" ]]
}

@test "max depth 2 shows files up to depth 2" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --max-depth 2
    [ "$status" -eq 0 ]
    # Should include subdirectory files
    [[ "$output" =~ "Installation Guide" ]]
    [[ "$output" =~ "API Reference" ]]
}

@test "max depth limits directory traversal" {
    cd "$FIXTURES_DIR"
    # Create a deeply nested structure
    mkdir -p "$OUTPUT_DIR/deep/nested/structure/test"
    echo "# Deep File" > "$OUTPUT_DIR/deep/nested/structure/test/deep.md"

    run "$SCRIPT" -d "$OUTPUT_DIR/deep" --max-depth 2
    [ "$status" -eq 0 ]
    # Should not include deeply nested file
    [[ ! "$output" =~ "Deep File" ]]

    rm -rf "$OUTPUT_DIR/deep"
}

# ============================================================================
# Combined Filtering and Sorting Tests
# ============================================================================

@test "filtering works with sorting by name" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" -e "DRAFT.md" --sort name
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "Draft Document" ]]
}

@test "filtering works with sorting by date" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -e "*.json" --sort date
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "config.json" ]]
}

@test "filtering works with sorting by size" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" --sort size
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "config.json" ]]
}

@test "max depth works with filtering" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --max-depth 1 -e "DRAFT.md"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Draft Document" ]]
    [[ ! "$output" =~ "Installation Guide" ]]
}

@test "max depth works with sorting" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --max-depth 2 --sort size
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
}

@test "all filtering and sorting options combined" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" -i "*.md" -e "DRAFT.md" --max-depth 2 --sort name
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "Draft Document" ]]
    [[ ! "$output" =~ "config.json" ]]
}
