# Test Suite for Documentation ToC Generator

Comprehensive test suite for the `generate-docs-toc.sh` script using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## Overview

This test suite provides comprehensive coverage of all major features:

- **Core Functionality** (`test_generate_toc.bats`)
  - Basic script execution
  - Version and help display
  - Output modes (full, simple, quiet)
  - Directory and path handling
  - Content extraction
  - File metadata
  - File counting

- **Argument Parsing** (`test_arguments.bats`)
  - All command-line flags and options
  - Short and long form arguments
  - Combined arguments
  - Edge cases

- **Filtering and Sorting** (`test_filtering_sorting.bats`)
  - Include/exclude patterns
  - Sort by name, date, and size
  - Maximum depth control
  - Combined filtering and sorting

- **Grouping** (`test_grouping.bats`)
  - Group by directory
  - Group by file type
  - Flat list (no grouping)
  - Grouping with other options

- **Markdown Processing** (`test_markdown.bats`)
  - Heading extraction (h1, h2)
  - Snippet extraction
  - Markdown formatting stripping
  - Special cases and edge cases
  - No-snippets mode

## Prerequisites

### Install Bats

**macOS (Homebrew):**
```bash
brew install bats-core
```

**Linux (apt):**
```bash
sudo apt-get install bats
```

**Linux (yum):**
```bash
sudo yum install bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Install GNU Parallel (Optional, for faster execution)

For **~3x faster** test execution, install GNU parallel:

**macOS (Homebrew):**
```bash
brew install parallel
```

**Linux (apt):**
```bash
sudo apt-get install parallel
```

**Linux (yum):**
```bash
sudo yum install parallel
```

**Performance:**
- **Sequential**: ~18 seconds (148 tests)
- **Parallel** (14 cores): ~6 seconds (148 tests)
- **Speedup**: ~3x faster

## Running Tests

### Run All Tests (Parallel - Default)

By default, tests run in parallel using all available CPU cores:

```bash
./run_tests.sh
```

This auto-detects your CPU count and runs tests in parallel for maximum speed (~3x faster).

### Run Tests Sequentially

If you prefer sequential execution:

```bash
./run_tests.sh --no-parallel
```

### Specify Number of Parallel Jobs

```bash
./run_tests.sh --jobs 4    # Use 4 parallel jobs
./run_tests.sh -j 8        # Use 8 parallel jobs
```

### Run Specific Test File

```bash
./run_tests.sh test_generate_toc.bats
```

or

```bash
bats tests/test_generate_toc.bats
```

### Run Tests with Verbose Output

```bash
./run_tests.sh --verbose
```

### Run Tests Matching a Pattern

```bash
./run_tests.sh --filter "heading"
```

This will run only tests with "heading" in their name.

### TAP Output Format

```bash
./run_tests.sh --tap
```

### Performance Comparison

```bash
# Parallel execution (default, faster)
./run_tests.sh                  # ~6 seconds on 14-core CPU

# Sequential execution (slower, easier to debug)
./run_tests.sh --no-parallel    # ~18 seconds
```

## Test Structure

```
tests/
├── README.md                       # This file
├── run_tests.sh                    # Test runner script
├── test_generate_toc.bats          # Core functionality tests
├── test_arguments.bats             # Argument parsing tests
├── test_filtering_sorting.bats     # Filtering and sorting tests
├── test_grouping.bats              # Grouping functionality tests
├── test_markdown.bats              # Markdown processing tests
├── fixtures/                       # Test fixtures
│   └── docs/                       # Sample documentation files
│       ├── README.md
│       ├── DRAFT.md
│       ├── no-heading.md
│       ├── config.json
│       ├── getting-started/
│       │   ├── installation.md
│       │   └── quickstart.md
│       ├── api/
│       │   ├── reference.md
│       │   └── examples.md
│       └── guides/
│           ├── advanced.md
│           └── troubleshooting.md
└── output/                         # Test output (auto-cleaned)
```

## Writing New Tests

### Test File Template

```bash
#!/usr/bin/env bats

# Test suite description

setup() {
    TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    SCRIPT="$PROJECT_ROOT/generate-docs-toc.sh"
    FIXTURES_DIR="$TEST_DIR/fixtures"
    OUTPUT_DIR="$TEST_DIR/output"
    TEST_OUTPUT="$OUTPUT_DIR/test-output.md"

    mkdir -p "$OUTPUT_DIR"
    rm -f "$TEST_OUTPUT"
}

teardown() {
    rm -f "$TEST_OUTPUT"
}

@test "test description" {
    run "$SCRIPT" [options]
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected text" ]]
}
```

### Bats Test Syntax

- `@test "description" { ... }` - Define a test
- `run <command>` - Run command and capture output
- `[ "$status" -eq 0 ]` - Assert exit code
- `[[ "$output" =~ "pattern" ]]` - Assert output contains pattern
- `[ -f "$file" ]` - Assert file exists
- `setup()` - Run before each test
- `teardown()` - Run after each test

### Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up created files in teardown
3. **Assertions**: Use clear, specific assertions
4. **Fixtures**: Use the fixtures directory for test data
5. **Naming**: Use descriptive test names
6. **Edge Cases**: Test boundary conditions and error cases

## Test Coverage

### Current Coverage

- ✅ All command-line arguments
- ✅ All output modes
- ✅ All grouping options
- ✅ All sorting options
- ✅ Include/exclude filtering
- ✅ Depth control
- ✅ Heading extraction
- ✅ Snippet extraction
- ✅ Markdown stripping
- ✅ File metadata
- ✅ Cross-platform compatibility checks
- ✅ Error handling

### Coverage Statistics

Total tests: 150+

Breakdown by category:
- Core functionality: ~30 tests
- Argument parsing: ~40 tests
- Filtering/sorting: ~35 tests
- Grouping: ~30 tests
- Markdown processing: ~40 tests

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats

      - name: Run tests
        run: |
          cd tests
          ./run_tests.sh
```

## Troubleshooting

### Bats Not Found

Ensure bats is installed and in your PATH:
```bash
which bats
```

### Tests Failing

Run with verbose output to see details:
```bash
./run_tests.sh --verbose
```

### Permission Denied

Make sure the test runner is executable:
```bash
chmod +x run_tests.sh
```

### Fixture Issues

Ensure the fixtures directory exists and contains test files:
```bash
ls -la fixtures/docs/
```

## Contributing

When adding new features to `generate-docs-toc.sh`:

1. Write tests first (TDD approach)
2. Ensure all existing tests pass
3. Add tests for the new feature
4. Run the full test suite before committing
5. Update this README if adding new test files

## License

Same as the main project (MIT License)
