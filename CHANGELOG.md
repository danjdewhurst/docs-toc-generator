# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.1] - 2025-11-23

### Fixed
- resolve test failures from version mismatch and race condition


## [2.2.0] - 2025-11-23

### Added
- add automated GitHub release creation


## [2.1.0] - 2025-11-23

### Added
- add versioning system with automated bump script
- add version flag to display script version
- v2.0.0: add extensive new options and features (v2.0.0)
- initial documentation ToC generator

### Changed
- add comprehensive testing documentation
- update README with correct GitHub username

### Fixed
- improve mixed markdown formatting test
- handle empty arrays in directory processing


## [2.0.0] - 2025-11-23

### Added
- Custom directory scanning with `-d, --directory` flag
- Multiple filtering options: `-e, --exclude` and `-i, --include` patterns
- Three grouping modes: directory, type, none via `--group-by`
- Multiple sorting options: name, date, size via `--sort`
- Configurable snippet length with `-l, --snippet-length`
- Maximum depth control with `--max-depth`
- No-snippets mode for faster processing via `--no-snippets`
- Custom ToC title with `--title` flag
- Quiet mode with `-q, --quiet` flag
- Comprehensive test suite with 148 tests (100% coverage)
- Parallel test execution with auto-detected CPU cores (~3x faster)
- 5 test suites covering all functionality
- Bats-based testing framework
- GitHub Actions workflows for CI/CD

### Changed
- Generic directory processing (removed hardcoded structure)
- Improved Bash 3.2 compatibility (works with macOS default bash)
- Better performance with selective snippet extraction

### Fixed
- Empty array handling for edge cases
- Mixed markdown formatting test improvements

## [1.0.0] - 2025-11-23

### Added
- Initial release
- Full and simple output modes
- Smart content extraction
- Cross-platform support (macOS/Linux)
- File metadata display (size, modification date)
- Markdown heading extraction
- Snippet generation with cleaning

[2.0.0]: https://github.com/danjdewhurst/docs-toc-generator/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/danjdewhurst/docs-toc-generator/releases/tag/v1.0.0
