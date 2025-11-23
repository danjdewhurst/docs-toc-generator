# Quick Start Guide

Get up and running with the test suite in 2 minutes.

## Installation

### 1. Install Bats

**macOS:**
```bash
brew install bats-core
```

**Linux:**
```bash
sudo apt-get install bats  # Ubuntu/Debian
# or
sudo yum install bats      # RHEL/CentOS
```

### 2. Install GNU Parallel (Optional - Recommended)

For **3x faster** test execution:

**macOS:**
```bash
brew install parallel
```

**Linux:**
```bash
sudo apt-get install parallel  # Ubuntu/Debian
# or
sudo yum install parallel      # RHEL/CentOS
```

### 3. Verify Installation

```bash
bats --version
parallel --version  # Optional
```

You should see something like: `Bats 1.x.x`

## Running Tests

### Run All Tests (Fast - Parallel Mode)

Tests run in parallel by default (~6 seconds on modern CPUs):

```bash
cd tests
./run_tests.sh
```

### Run Sequentially (Slower, easier to debug)

```bash
./run_tests.sh --no-parallel    # ~18 seconds
```

### Run Specific Test Suite

```bash
./run_tests.sh test_generate_toc.bats      # Core functionality
./run_tests.sh test_arguments.bats         # Argument parsing
./run_tests.sh test_filtering_sorting.bats # Filtering & sorting
./run_tests.sh test_grouping.bats          # Grouping options
./run_tests.sh test_markdown.bats          # Markdown processing
```

### Run with Verbose Output

```bash
./run_tests.sh --verbose
```

### Run Specific Tests

```bash
./run_tests.sh --filter "heading"  # Only tests matching "heading"
```

### Custom Parallelism

```bash
./run_tests.sh -j 4    # Use 4 parallel jobs
```

## Test Results

```
✓ script exists and is executable
✓ script runs without errors with default options
✓ script displays version with -v flag
...

150 tests, 0 failures
```

## Troubleshooting

### "bats: command not found"

Install bats (see Installation section above)

### "Permission denied"

```bash
chmod +x run_tests.sh
```

### Tests fail

Run with verbose output to see details:
```bash
./run_tests.sh --verbose
```

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check [test_generate_toc.bats](test_generate_toc.bats:1) for examples
- Add your own tests following the existing patterns

## Help

```bash
./run_tests.sh --help
```
