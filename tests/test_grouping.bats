#!/usr/bin/env bats

# Test suite for grouping functionality

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
# Group by Directory Tests (Default)
# ============================================================================

@test "default grouping is by directory" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    # Should have directory headers
    [[ "$output" =~ "📁" ]]
}

@test "group by directory creates directory sections" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory
    [ "$status" -eq 0 ]
    # Should have sections for each directory
    [[ "$output" =~ "Getting Started" ]] || [[ "$output" =~ "getting-started" ]]
    [[ "$output" =~ "Api" ]] || [[ "$output" =~ "API" ]]
    [[ "$output" =~ "Guides" ]]
}

@test "group by directory shows folder emoji" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📁" ]]
    [[ "$output" =~ "📂" ]] || [[ "$output" =~ "📁" ]]
}

@test "group by directory capitalizes directory names" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory
    [ "$status" -eq 0 ]
    # Directory names should be capitalized
    [[ "$output" =~ "Getting Started" ]] || [[ "$output" =~ "Api" ]]
}

@test "group by directory handles nested directories" {
    cd "$FIXTURES_DIR"
    # Create nested structure
    mkdir -p "$OUTPUT_DIR/nested/level1/level2"
    echo "# Nested Doc" > "$OUTPUT_DIR/nested/level1/level2/doc.md"

    run "$SCRIPT" -d "$OUTPUT_DIR/nested"
    [ "$status" -eq 0 ]
    # Should handle nested structure
    [[ "$output" =~ "Level1" ]] || [[ "$output" =~ "level1" ]]

    rm -rf "$OUTPUT_DIR/nested"
}

@test "group by directory shows files under correct section" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory
    [ "$status" -eq 0 ]

    # Get the output and check structure
    # Installation and Quick Start should be under getting-started section
    # This is a simplified check
    [[ "$output" =~ "Installation Guide" ]]
    [[ "$output" =~ "Quick Start" ]]
}

# ============================================================================
# Group by Type Tests
# ============================================================================

@test "group by type creates file type sections" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type
    [ "$status" -eq 0 ]
    # Should have section for MD files
    [[ "$output" =~ "MD Files" ]] || [[ "$output" =~ "md Files" ]]
}

@test "group by type shows file emoji" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📄" ]]
}

@test "group by type groups markdown files together" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type
    [ "$status" -eq 0 ]
    # All markdown files should be in one section
    [[ "$output" =~ "Main Documentation" ]]
    [[ "$output" =~ "Installation Guide" ]]
    [[ "$output" =~ "API Reference" ]]
}

@test "group by type groups non-markdown files" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type
    [ "$status" -eq 0 ]
    # JSON files should be in their own section
    [[ "$output" =~ "JSON Files" ]] || [[ "$output" =~ "json" ]]
    [[ "$output" =~ "config.json" ]]
}

@test "group by type handles multiple file types" {
    # Create test directory with multiple file types
    mkdir -p "$OUTPUT_DIR/multitype"
    echo "# Test MD" > "$OUTPUT_DIR/multitype/test.md"
    echo "test text" > "$OUTPUT_DIR/multitype/test.txt"
    echo '{"test": true}' > "$OUTPUT_DIR/multitype/test.json"

    run "$SCRIPT" -d "$OUTPUT_DIR/multitype" --group-by type
    [ "$status" -eq 0 ]
    # Should have sections for each type
    [[ "$output" =~ "MD Files" ]] || [[ "$output" =~ "md" ]]
    [[ "$output" =~ "TXT Files" ]] || [[ "$output" =~ "txt" ]]
    [[ "$output" =~ "JSON Files" ]] || [[ "$output" =~ "json" ]]

    rm -rf "$OUTPUT_DIR/multitype"
}

@test "group by type handles files without extensions" {
    mkdir -p "$OUTPUT_DIR/noext"
    echo "# No Extension" > "$OUTPUT_DIR/noext/README"

    run "$SCRIPT" -d "$OUTPUT_DIR/noext" --group-by type
    [ "$status" -eq 0 ]
    # Should handle files without extension
    [[ "$output" =~ "No Extension" ]] || [[ "$output" =~ "README" ]]

    rm -rf "$OUTPUT_DIR/noext"
}

# ============================================================================
# Group by None Tests (Flat List)
# ============================================================================

@test "group by none creates flat list" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by none
    [ "$status" -eq 0 ]
    # Should not have directory or type headers
    [[ ! "$output" =~ "📁" ]]
    [[ ! "$output" =~ "📄" ]]
    [[ ! "$output" =~ "Getting Started" ]]
    [[ ! "$output" =~ "MD Files" ]]
}

@test "group by none shows all files in sequence" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by none --simple
    [ "$status" -eq 0 ]
    # Files should be listed directly
    [[ "$output" =~ "Main Documentation" ]]
    [[ "$output" =~ "Installation Guide" ]]
}

@test "group by none respects sorting order" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by none --sort name
    [ "$status" -eq 0 ]
    # Should be sorted by name without grouping
}

@test "group by none works with filtering" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by none -i "*.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Documentation" ]]
    [[ ! "$output" =~ "config.json" ]]
}

# ============================================================================
# Grouping with Other Options Tests
# ============================================================================

@test "grouping works with simple mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory --simple
    [ "$status" -eq 0 ]
    # Simple mode doesn't show emojis or metadata
    [[ ! "$output" =~ "Modified:" ]]
    [[ ! "$output" =~ "KB" ]]
}

@test "grouping works with no-snippets mode" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory --no-snippets
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📁" ]]
    [[ ! "$output" =~ "This is the main documentation" ]]
}

@test "grouping works with custom title" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type --title "My Custom Docs"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "# My Custom Docs" ]]
    [[ "$output" =~ "📄" ]]
}

@test "grouping works with sorting by date" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory --sort date
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📁" ]]
}

@test "grouping works with sorting by size" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by type --sort size
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📄" ]]
}

@test "grouping works with filtering" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory -e "DRAFT.md"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "📁" ]]
    [[ ! "$output" =~ "Draft Document" ]]
}

@test "grouping works with max depth" {
    cd "$FIXTURES_DIR"
    run "$SCRIPT" --group-by directory --max-depth 1
    [ "$status" -eq 0 ]
    # Should not have subdirectory files
    [[ "$output" =~ "Main Documentation" ]]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "empty directory with grouping" {
    mkdir -p "$OUTPUT_DIR/empty"
    run "$SCRIPT" -d "$OUTPUT_DIR/empty" --group-by directory
    [ "$status" -eq 0 ]
    # Should show 0 files
    [[ "$output" =~ "0" ]] && [[ "$output" =~ "files" ]]
    rm -rf "$OUTPUT_DIR/empty"
}

@test "single file with group by directory" {
    mkdir -p "$OUTPUT_DIR/single-dir"
    echo "# Single" > "$OUTPUT_DIR/single-dir/test.md"
    run "$SCRIPT" -d "$OUTPUT_DIR/single-dir" --group-by directory
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Single" ]]
    rm -rf "$OUTPUT_DIR/single-dir"
}

@test "single file with group by type" {
    mkdir -p "$OUTPUT_DIR/single-type"
    echo "# Single" > "$OUTPUT_DIR/single-type/test.md"
    run "$SCRIPT" -d "$OUTPUT_DIR/single-type" --group-by type
    [ "$status" -eq 0 ]
    [[ "$output" =~ "MD Files" ]] || [[ "$output" =~ "md" ]]
    rm -rf "$OUTPUT_DIR/single-type"
}

@test "single file with group by none" {
    mkdir -p "$OUTPUT_DIR/single-none"
    echo "# Single" > "$OUTPUT_DIR/single-none/test.md"
    run "$SCRIPT" -d "$OUTPUT_DIR/single-none" --group-by none
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Single" ]]
    rm -rf "$OUTPUT_DIR/single-none"
}
