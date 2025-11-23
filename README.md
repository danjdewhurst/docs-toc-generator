# Documentation ToC Generator

A fast, efficient bash script that automatically generates a table of contents for your documentation files with smart content extraction and metadata.

[![Test Suite](https://github.com/danjdewhurst/docs-toc-generator/actions/workflows/test.yml/badge.svg)](https://github.com/danjdewhurst/docs-toc-generator/actions/workflows/test.yml)
[![Tests](https://img.shields.io/badge/tests-148%20passing-brightgreen)](tests/)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](tests/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-3.2%2B-blue.svg)](https://www.gnu.org/software/bash/)

## Features

- **Smart Content Extraction**: Automatically extracts headings and meaningful snippets from markdown files
- **Flexible Directory Scanning**: Specify any directory to scan, not just `docs/`
- **Multiple Output Modes**:
  - **Full Mode**: Rich output with snippets, file sizes, and modification dates
  - **Simple Mode**: Clean, minimal list of files and titles
  - **No-Snippets Mode**: Faster processing by skipping content extraction
- **Advanced Filtering**:
  - Include/exclude patterns for fine-grained file selection
  - Support for multiple patterns per filter
- **Flexible Grouping**:
  - Group by directory (default)
  - Group by file type/extension
  - No grouping (flat list)
- **Multiple Sorting Options**: Sort by name, date, or size
- **Depth Control**: Limit directory traversal depth
- **Customizable**:
  - Custom ToC title
  - Configurable snippet length
  - Quiet mode for scripting
- **Cross-Platform**: Compatible with Bash 3.2+ (works on macOS and Linux)
- **Fast Performance**: Single-pass file reading with efficient parsing

## Installation

### Quick Install

```bash
curl -o generate-docs-toc.sh https://raw.githubusercontent.com/danjdewhurst/docs-toc-generator/main/generate-docs-toc.sh
chmod +x generate-docs-toc.sh
```

### Manual Install

1. Clone the repository:
```bash
git clone https://github.com/danjdewhurst/docs-toc-generator.git
cd docs-toc-generator
```

2. Make the script executable:
```bash
chmod +x generate-docs-toc.sh
```

3. (Optional) Add to your PATH:
```bash
sudo cp generate-docs-toc.sh /usr/local/bin/generate-docs-toc
```

## Usage

### Basic Usage

Generate and print ToC to stdout (uses `docs/` directory by default):
```bash
./generate-docs-toc.sh
```

### Custom Directory

Scan a different documentation directory:
```bash
./generate-docs-toc.sh -d documentation
```

### Output to File

Write ToC to a specific file:
```bash
./generate-docs-toc.sh -o docs/README.md
```

### Simple Mode

Generate a minimal ToC without metadata:
```bash
./generate-docs-toc.sh --simple
```

### Filtering Files

Exclude specific files or patterns:
```bash
./generate-docs-toc.sh -e "*.draft.md" -e "tmp/" -e "archive/"
```

Include only specific files:
```bash
./generate-docs-toc.sh -i "*.md"
```

### Sorting Options

Sort by modification date (newest first):
```bash
./generate-docs-toc.sh --sort date
```

Sort by file size (largest first):
```bash
./generate-docs-toc.sh --sort size
```

### Grouping Options

Group by file type instead of directory:
```bash
./generate-docs-toc.sh --group-by type
```

No grouping (flat list):
```bash
./generate-docs-toc.sh --group-by none
```

### Performance Optimization

Disable snippet extraction for faster processing:
```bash
./generate-docs-toc.sh --no-snippets
```

Limit directory depth:
```bash
./generate-docs-toc.sh --max-depth 2
```

### Custom Snippet Length

Set custom snippet length (default is 200 characters):
```bash
./generate-docs-toc.sh -l 300
```

### Custom Title

Set a custom title for the ToC:
```bash
./generate-docs-toc.sh --title "API Documentation Index"
```

### Quiet Mode

Suppress progress messages (useful in scripts):
```bash
./generate-docs-toc.sh -o TOC.md -q
```

### Combined Options

Here are some useful combinations:

Generate a clean, fast ToC with filtering:
```bash
./generate-docs-toc.sh -d docs -o README.md --no-snippets -e "*.draft.md" -q
```

API documentation index sorted by date:
```bash
./generate-docs-toc.sh -d api --title "API Reference" --sort date --group-by type
```

Only markdown files, limited depth, custom snippets:
```bash
./generate-docs-toc.sh -i "*.md" --max-depth 3 -l 150

## Options

| Option | Description |
|--------|-------------|
| `-d, --directory DIR` | Documentation directory to scan (default: `docs`) |
| `-o, --output FILE` | Write output to FILE instead of stdout |
| `-s, --simple` | Simple mode (only paths and titles, no metadata) |
| `-l, --snippet-length NUM` | Maximum snippet length in characters (default: 200) |
| `--max-depth NUM` | Maximum directory depth to traverse (default: unlimited) |
| `--sort [name\|date\|size]` | Sort files by name, date, or size (default: name) |
| `-e, --exclude PATTERN` | Exclude files/dirs matching pattern (can be used multiple times) |
| `-i, --include PATTERN` | Only include files matching pattern (can be used multiple times) |
| `--no-snippets` | Disable snippet extraction for faster processing |
| `--title TEXT` | Custom title for table of contents |
| `--group-by [directory\|type\|none]` | How to group files (default: directory) |
| `-q, --quiet` | Suppress progress messages |
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |

## Output Examples

### Full Mode

```markdown
# Documentation Table of Contents

Generated: 2025-11-23

**Total files:** 15 (12 markdown files)

---

## 📁 Plans

- **[Project Roadmap](docs/plans/roadmap.md)**
  This document outlines the strategic direction and planned features for the next quarter...
  *3KB • Modified: 2025-11-15*

- **[Architecture Design](docs/plans/architecture.md)**
  Comprehensive system architecture covering microservices, data flow, and integration patterns...
  *5KB • Modified: 2025-11-20*
```

### Simple Mode

```markdown
# Documentation Table of Contents

- [Project Roadmap](docs/plans/roadmap.md)
- [Architecture Design](docs/plans/architecture.md)
- [API Reference](docs/api/reference.md)
```

## How It Works

The script processes your documentation directory (`docs/` by default) and:

1. **Scans** all files in the documentation directory
2. **Extracts** the first heading (h1 or h2) from each markdown file
3. **Collects** a meaningful snippet of content (up to 200 characters)
4. **Strips** markdown formatting for clean display
5. **Gathers** file metadata (size and modification date)
6. **Generates** a formatted table of contents in markdown

### Smart Content Extraction

The script intelligently:
- Skips empty lines and horizontal rules
- Ignores metadata blocks and nested headings
- Cleans markdown syntax (bold, italic, code, links)
- Finds the most relevant content snippet

## Requirements

- Bash 3.2 or later (compatible with macOS default bash)
- Standard Unix utilities: `find`, `sed`, `stat`, `awk`
- Works on macOS and Linux

## Use Cases

- **Project Documentation**: Generate indexes for project wikis
- **Knowledge Bases**: Create navigable ToCs for large documentation sets
- **Static Sites**: Auto-generate documentation indexes
- **CI/CD Integration**: Automatically update ToC on documentation changes
- **Documentation Audits**: Quickly review all documentation with snippets

## Integration Examples

### Git Hook (Auto-update on commit)

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
./generate-docs-toc.sh -o docs/README.md
git add docs/README.md
```

### GitHub Actions

**Auto-update ToC on documentation changes:**
```yaml
name: Update Documentation ToC
on:
  push:
    paths:
      - 'docs/**'
jobs:
  update-toc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Generate ToC
        run: |
          chmod +x generate-docs-toc.sh
          ./generate-docs-toc.sh -o docs/README.md
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/README.md
          git commit -m "Auto-update documentation ToC" || exit 0
          git push
```

**Run tests on pull requests:**
```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats parallel
      - name: Run tests
        run: |
          cd tests
          ./run_tests.sh
```

### Makefile Integration

```makefile
.PHONY: docs-toc
docs-toc:
	./generate-docs-toc.sh -o docs/README.md
	@echo "Documentation ToC updated!"
```

## Performance

The script is optimized for performance:
- Single-pass file reading (no multiple file reads)
- Efficient regex matching with bash built-ins
- Minimal external command calls
- Handles hundreds of files quickly

## Testing

This project includes a comprehensive test suite with **148 tests** covering all functionality.

### Quick Test Run

```bash
cd tests
./run_tests.sh
```

**Performance:** Tests run in parallel by default (~6 seconds on modern CPUs)

### Test Coverage

- ✅ **Core Functionality** (30 tests) - Script execution, output modes, metadata
- ✅ **Command-line Arguments** (31 tests) - All flags and options
- ✅ **Filtering & Sorting** (27 tests) - Include/exclude patterns, sort modes
- ✅ **Grouping Options** (29 tests) - Directory, type, and flat grouping
- ✅ **Markdown Processing** (31 tests) - Heading extraction, snippet generation

### Prerequisites

**Install Bats:**
```bash
brew install bats-core  # macOS
# or
sudo apt-get install bats  # Linux
```

**Optional - Install GNU Parallel for 3x faster tests:**
```bash
brew install parallel  # macOS
# or
sudo apt-get install parallel  # Linux
```

### Test Options

```bash
./run_tests.sh                  # Run all tests in parallel (~6 sec)
./run_tests.sh --no-parallel    # Sequential execution (~18 sec)
./run_tests.sh -j 4             # Use 4 parallel jobs
./run_tests.sh --verbose        # Detailed output
./run_tests.sh --filter "heading"  # Run specific tests
```

### Test Results

```
Total Tests:  148 ✓
Success Rate: 100%
Time:         ~6 seconds (parallel) / ~18 seconds (sequential)
```

For more details, see [tests/README.md](tests/README.md) or [tests/QUICK_START.md](tests/QUICK_START.md)

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. **Run the test suite** to ensure everything works:
   ```bash
   cd tests
   ./run_tests.sh
   ```
5. Add tests for new features
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

All pull requests must pass the test suite (148 tests) before merging.

## Author

Created with ❤️ for better documentation management

## Changelog

### 2.0.0 (2025-11-23)
- **New Features**:
  - Custom directory scanning (`-d, --directory`)
  - Multiple filtering options (`-e, --exclude`, `-i, --include`)
  - Three grouping modes: directory, type, none (`--group-by`)
  - Multiple sorting options: name, date, size (`--sort`)
  - Configurable snippet length (`-l, --snippet-length`)
  - Maximum depth control (`--max-depth`)
  - No-snippets mode for faster processing (`--no-snippets`)
  - Custom ToC title (`--title`)
  - Quiet mode (`-q, --quiet`)
- **Testing**:
  - Comprehensive test suite with 148 tests (100% coverage)
  - Parallel test execution with auto-detected CPU cores (~3x faster)
  - 5 test suites covering all functionality
  - Bats-based testing framework
- **Improvements**:
  - Generic directory processing (removed hardcoded structure)
  - Bash 3.2 compatibility (works with macOS default bash)
  - Better performance with selective snippet extraction
  - Fixed empty array handling for edge cases
- **Breaking Changes**:
  - None (all new features are opt-in via flags)

### 1.0.0 (2025-11-23)
- Initial release
- Full and simple output modes
- Smart content extraction
- Cross-platform support (macOS/Linux)
- File metadata display
