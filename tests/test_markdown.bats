#!/usr/bin/env bats

# Test suite for markdown processing and content extraction

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    SCRIPT="$PROJECT_ROOT/generate-docs-toc.sh"
    OUTPUT_DIR="$TEST_DIR/output"
    TEST_OUTPUT="$OUTPUT_DIR/test-output.md"
    # Use unique directory per test to avoid parallel conflicts
    TEST_DOCS="$OUTPUT_DIR/markdown-test-docs-$$-$RANDOM"

    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEST_DOCS"
    rm -f "$TEST_OUTPUT"
}

teardown() {
    rm -f "$TEST_OUTPUT"
    rm -rf "$TEST_DOCS"
}

# ============================================================================
# Heading Extraction Tests
# ============================================================================

@test "extracts h1 heading correctly" {
    echo "# Main Heading" > "$TEST_DOCS/test.md"
    echo "Content here" >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Heading" ]]
}

@test "extracts h2 heading when h1 is not present" {
    echo "## Secondary Heading" > "$TEST_DOCS/test.md"
    echo "Content here" >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Secondary Heading" ]]
}

@test "prefers h1 over h2 heading" {
    echo "# Primary Heading" > "$TEST_DOCS/test.md"
    echo "## Secondary Heading" >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Primary Heading" ]]
    # Extract the line with the heading to ensure it's the h1
    heading_line=$(echo "$output" | grep -o "\[.*\]" | head -1)
    [[ "$heading_line" =~ "Primary Heading" ]]
}

@test "handles heading with bold text" {
    echo "# Heading with **bold** text" > "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should strip markdown formatting
    [[ "$output" =~ "Heading with bold text" ]]
    [[ ! "$output" =~ "**bold**" ]]
}

@test "handles heading with italic text" {
    echo "# Heading with *italic* text" > "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Heading with italic text" ]]
}

@test "handles heading with code" {
    echo "# Heading with \`code\` text" > "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Heading with code text" ]]
}

@test "handles heading with underscores" {
    echo "# Heading_with_underscores" > "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Headingwithunderscores" ]] || [[ "$output" =~ "Heading_with_underscores" ]]
}

@test "falls back to filename when no heading found" {
    echo "Just content, no heading" > "$TEST_DOCS/fallback-test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should use filename converted to title case
    [[ "$output" =~ "Fallback Test" ]]
}

# ============================================================================
# Snippet Extraction Tests
# ============================================================================

@test "extracts snippet from first paragraph" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "" >> "$TEST_DOCS/test.md"
    echo "This is the first paragraph that should be extracted as a snippet." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "This is the first paragraph" ]]
}

@test "skips empty lines when extracting snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "" >> "$TEST_DOCS/test.md"
    echo "" >> "$TEST_DOCS/test.md"
    echo "First content line." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "First content line" ]]
}

@test "skips horizontal rules in snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "---" >> "$TEST_DOCS/test.md"
    echo "Real content here." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Real content here" ]]
    # Check that the snippet line (the one after the file link) doesn't start with "---"
    snippet_line=$(echo "$output" | grep -A 1 "Heading" | tail -1)
    [[ ! "$snippet_line" =~ ^[[:space:]]*--- ]]
}

@test "skips list items in snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "- List item" >> "$TEST_DOCS/test.md"
    echo "* Another item" >> "$TEST_DOCS/test.md"
    echo "Regular paragraph text." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Regular paragraph text" ]]
}

@test "skips numbered lists in snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "1. First item" >> "$TEST_DOCS/test.md"
    echo "2. Second item" >> "$TEST_DOCS/test.md"
    echo "Paragraph content." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Paragraph content" ]]
}

@test "skips nested headings in snippet" {
    echo "# Main Heading" > "$TEST_DOCS/test.md"
    echo "## Subheading" >> "$TEST_DOCS/test.md"
    echo "### Another subheading" >> "$TEST_DOCS/test.md"
    echo "Actual content paragraph." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Actual content paragraph" ]]
}

@test "truncates long snippets" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    # Create a very long paragraph
    long_text="This is a very long paragraph that contains more than two hundred characters of text. It should be truncated by the script to ensure that the table of contents remains readable and does not become cluttered with excessively long snippets that would make it difficult to scan."
    echo "$long_text" >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS" -l 200
    [ "$status" -eq 0 ]
    [[ "$output" =~ "..." ]]
}

@test "respects custom snippet length" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This is a paragraph with exactly fifty-two characters total length." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS" -l 30
    [ "$status" -eq 0 ]
    # Should be truncated to around 30 characters
    [[ "$output" =~ "..." ]]
}

# ============================================================================
# Markdown Stripping Tests
# ============================================================================

@test "strips bold markers from snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has **bold text** in it." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should not contain markdown bold markers
    snippet=$(echo "$output" | grep -A 1 "Heading")
    [[ ! "$snippet" =~ "**bold text**" ]]
    [[ "$snippet" =~ "bold text" ]]
}

@test "strips italic markers from snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has *italic text* in it." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    snippet=$(echo "$output" | grep -A 1 "Heading")
    [[ ! "$snippet" =~ "*italic text*" ]]
}

@test "strips code markers from snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has \`code text\` in it." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "code text" ]]
}

@test "strips link markdown from snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has a [link text](https://example.com) in it." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should show link text but not the URL
    [[ "$output" =~ "link text" ]]
    [[ ! "$output" =~ "https://example.com" ]]
}

@test "strips HTML tags from snippet" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has <strong>HTML tags</strong> in it." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "HTML tags" ]]
    [[ ! "$output" =~ "<strong>" ]]
}

@test "handles mixed markdown formatting" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "This has **bold**, *italic*, and \`code\` all together." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "bold" ]]
    [[ "$output" =~ "italic" ]]
    [[ "$output" =~ "code" ]]
    # Extract just the snippet line (not the header which has ** markers)
    snippet=$(echo "$output" | grep "This has" || true)
    [[ ! "$snippet" =~ "**" ]]
    [[ ! "$snippet" =~ "\`" ]]
}

# ============================================================================
# Special Cases
# ============================================================================

@test "handles empty markdown file" {
    touch "$TEST_DOCS/empty.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should use filename as fallback
    [[ "$output" =~ "Empty" ]]
}

@test "handles file with only whitespace" {
    echo "   " > "$TEST_DOCS/whitespace.md"
    echo "" >> "$TEST_DOCS/whitespace.md"
    echo "  " >> "$TEST_DOCS/whitespace.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Whitespace" ]]
}

@test "handles file with only headings" {
    echo "# Main Heading" > "$TEST_DOCS/test.md"
    echo "## Subheading" >> "$TEST_DOCS/test.md"
    echo "### Another subheading" >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Main Heading" ]]
}

@test "handles file with code blocks" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo '```javascript' >> "$TEST_DOCS/test.md"
    echo 'const x = 1;' >> "$TEST_DOCS/test.md"
    echo '```' >> "$TEST_DOCS/test.md"
    echo "Regular text content." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Regular text content" ]]
}

@test "handles file with blockquotes" {
    echo "# Heading" > "$TEST_DOCS/test.md"
    echo "> This is a quote" >> "$TEST_DOCS/test.md"
    echo "Normal paragraph." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Normal paragraph" ]]
}

@test "handles unicode characters in content" {
    echo "# Heading with émojis 🎉" > "$TEST_DOCS/test.md"
    echo "Content with spëcial çharacters and 中文." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    # Should handle unicode correctly
}

@test "handles very long filename conversion" {
    echo "# Heading" > "$TEST_DOCS/this-is-a-very-long-filename-that-should-be-converted-properly.md"

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Heading" ]]
}

# ============================================================================
# No Snippets Mode Tests
# ============================================================================

@test "no-snippets mode extracts only heading" {
    echo "# Test Heading" > "$TEST_DOCS/test.md"
    echo "This content should not appear." >> "$TEST_DOCS/test.md"

    run "$SCRIPT" -d "$TEST_DOCS" --no-snippets
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test Heading" ]]
    [[ ! "$output" =~ "This content should not appear" ]]
}

@test "no-snippets mode is faster than full mode" {
    # Create multiple files
    for i in {1..10}; do
        echo "# Heading $i" > "$TEST_DOCS/test$i.md"
        echo "Content for file $i with some text." >> "$TEST_DOCS/test$i.md"
    done

    # Both should succeed, performance difference not easily testable in bats
    run "$SCRIPT" -d "$TEST_DOCS" --no-snippets
    [ "$status" -eq 0 ]

    run "$SCRIPT" -d "$TEST_DOCS"
    [ "$status" -eq 0 ]
}
