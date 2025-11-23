# Documentation ToC Generator

A fast, efficient bash script that automatically generates a table of contents for your documentation files with smart content extraction and metadata.

## Features

- **Smart Content Extraction**: Automatically extracts headings and meaningful snippets from markdown files
- **Two Output Modes**:
  - **Full Mode**: Rich output with snippets, file sizes, and modification dates
  - **Simple Mode**: Clean, minimal list of files and titles
- **Markdown Formatting Cleanup**: Strips markdown syntax from headings and snippets for clean display
- **Cross-Platform**: Works on both macOS and Linux
- **Customizable Output**: Write to file or stdout
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

Generate and print ToC to stdout:
```bash
./generate-docs-toc.sh
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

### Help

```bash
./generate-docs-toc.sh --help
```

## Options

| Option | Description |
|--------|-------------|
| `-o, --output FILE` | Write output to FILE instead of stdout |
| `-s, --simple` | Simple mode (only paths and titles, no metadata) |
| `-h, --help` | Show help message |

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

- Bash 4.0 or later
- Standard Unix utilities: `find`, `sed`, `stat`, `awk`
- Works on macOS and Linux

## Configuration

By default, the script looks for documentation in a `docs/` directory. To change this, edit the `DOCS_DIR` variable in the script:

```bash
DOCS_DIR="documentation"  # Change from "docs" to "documentation"
```

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

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

Created with ❤️ for better documentation management

## Changelog

### 1.0.0 (2025-11-23)
- Initial release
- Full and simple output modes
- Smart content extraction
- Cross-platform support (macOS/Linux)
- File metadata display
