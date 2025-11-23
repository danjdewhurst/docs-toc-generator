# Versioning Guide

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and uses [Conventional Commits](https://www.conventionalcommits.org/) for automated version management.

## Current Version

**v2.0.0**

The current version is tracked in:
- `VERSION` file
- `generate-docs-toc.sh` (VERSION variable)
- Git tags (e.g., `v2.0.0`)

## Semantic Versioning

Version format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New features (backwards-compatible functionality)
- **PATCH**: Bug fixes (backwards-compatible fixes)

## Conventional Commits

This project uses conventional commit messages to automatically determine version bumps:

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Common Types

| Type | Version Bump | Description | Example |
|------|--------------|-------------|---------|
| `feat` | MINOR | New feature | `feat: add custom title option` |
| `fix` | PATCH | Bug fix | `fix: handle empty arrays correctly` |
| `docs` | PATCH | Documentation only | `docs: update README examples` |
| `style` | PATCH | Formatting changes | `style: fix indentation` |
| `refactor` | PATCH | Code refactoring | `refactor: simplify parsing logic` |
| `perf` | PATCH | Performance improvements | `perf: optimize file reading` |
| `test` | PATCH | Adding tests | `test: add sorting tests` |
| `build` | PATCH | Build system changes | `build: update dependencies` |
| `ci` | PATCH | CI configuration | `ci: add GitHub Actions workflow` |
| `chore` | PATCH | Other changes | `chore: update .gitignore` |

### Breaking Changes

For MAJOR version bumps, use either:

1. Exclamation mark after type:
   ```
   feat!: remove deprecated --old-flag option
   ```

2. BREAKING CHANGE footer:
   ```
   feat: redesign configuration system

   BREAKING CHANGE: Configuration file format has changed from JSON to YAML
   ```

### Examples

```bash
# Patch version bump (2.0.0 → 2.0.1)
git commit -m "fix: correct date formatting in output"

# Minor version bump (2.0.0 → 2.1.0)
git commit -m "feat: add JSON output format"

# Major version bump (2.0.0 → 3.0.0)
git commit -m "feat!: redesign CLI interface"

# With scope
git commit -m "fix(parser): handle malformed markdown headings"

# Multi-line with body
git commit -m "feat: add configuration file support

Allow users to specify default options in a .toc-config file
to avoid repeating command-line flags."
```

## Version Bump Workflow

### Using the bump-version Script

The `bump-version.sh` script automates version management:

#### Auto-detect Version Bump

Analyzes commits since last tag and determines version bump:

```bash
./bump-version.sh
```

#### Manual Version Bump

Specify the bump type:

```bash
./bump-version.sh major  # 2.0.0 → 3.0.0
./bump-version.sh minor  # 2.0.0 → 2.1.0
./bump-version.sh patch  # 2.0.0 → 2.0.1
```

#### Set Specific Version

```bash
./bump-version.sh 3.1.4
```

#### With Git Tag

Create a git tag automatically:

```bash
./bump-version.sh --tag
./bump-version.sh minor --tag
```

#### With Push to Remote

Tag and push to remote repository:

```bash
./bump-version.sh --tag --push
# or
./bump-version.sh -t -p
```

#### Dry Run

Preview changes without modifying files:

```bash
./bump-version.sh --dry-run
./bump-version.sh major --dry-run
```

### What the Script Does

1. **Analyzes commits** since last git tag
2. **Determines version bump** based on conventional commit types
3. **Updates files**:
   - `VERSION` file
   - `VERSION` variable in `generate-docs-toc.sh`
   - `CHANGELOG.md` with categorized changes
4. **Creates commit** with message: `chore: bump version to X.Y.Z`
5. **Creates git tag** (optional): `vX.Y.Z`
6. **Pushes changes** (optional)
7. **Triggers GitHub release** (when tags are pushed)

## GitHub Release Integration

This project includes automated GitHub release creation via GitHub Actions.

### How It Works

When you push a version tag (e.g., `v2.1.0`):

1. **GitHub Actions workflow triggers** (`.github/workflows/release.yml`)
2. **Release notes are extracted** from CHANGELOG.md for that version
3. **GitHub release is created** automatically with:
   - Release title: "Release v2.1.0"
   - Release notes from CHANGELOG.md
   - Release assets: `generate-docs-toc.sh`, `VERSION`, `CHANGELOG.md`

### Using with bump-version.sh

The easiest way to trigger a release:

```bash
./bump-version.sh --tag --push
```

This single command:
- Bumps the version
- Updates all files
- Creates a git commit
- Creates a git tag
- Pushes to remote
- **Automatically triggers GitHub release creation**

### Manual Release Creation

If you prefer manual control, you can still create releases manually:

```bash
# Bump and tag locally
./bump-version.sh --tag

# Review changes before pushing
git show HEAD
git show v2.1.0

# Push when ready (triggers release)
git push && git push --tags
```

## Manual Version Bump

If you prefer to bump versions manually:

### 1. Update VERSION File

```bash
echo "2.1.0" > VERSION
```

### 2. Update Script

Edit `generate-docs-toc.sh`:

```bash
VERSION="2.1.0"
```

### 3. Update CHANGELOG.md

Add new version section following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [2.1.0] - 2025-11-24

### Added
- New feature description

### Fixed
- Bug fix description
```

### 4. Commit and Tag

```bash
git add VERSION generate-docs-toc.sh CHANGELOG.md
git commit -m "chore: bump version to 2.1.0"
git tag -a v2.1.0 -m "Release version 2.1.0"
git push && git push --tags
```

## Release Checklist

Before creating a new release:

- [ ] All tests pass (`cd tests && ./run_tests.sh`)
- [ ] CHANGELOG.md is up to date
- [ ] Version numbers match in VERSION, script, and git tag
- [ ] README.md reflects current features
- [ ] No uncommitted changes
- [ ] All commits follow conventional commit format

## Release Process

### 1. Prepare Release

```bash
# Run tests
cd tests && ./run_tests.sh
cd ..

# Check git status
git status

# Review commits since last release
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

### 2. Bump Version

```bash
# Auto-detect and create tag
./bump-version.sh --tag

# Or specify version type
./bump-version.sh minor --tag
```

### 3. Push Release

```bash
# Push commits and tags (triggers automated GitHub release)
git push && git push --tags
```

### 4. Automated GitHub Release

When you push a version tag (e.g., `v2.1.0`), GitHub Actions automatically:

1. **Extracts release notes** from CHANGELOG.md for that version
2. **Creates a GitHub release** with the tag name
3. **Attaches release assets**:
   - `generate-docs-toc.sh` (the main script)
   - `VERSION` (version file)
   - `CHANGELOG.md` (full changelog)

**No manual steps required!** The release appears at:
https://github.com/danjdewhurst/docs-toc-generator/releases

You can view the automation workflow at `.github/workflows/release.yml`

## Version History

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## Git Tags

List all version tags:

```bash
git tag -l
```

View specific tag:

```bash
git show v2.0.0
```

Compare versions:

```bash
git diff v1.0.0..v2.0.0
```

## Troubleshooting

### No commits since last tag

If `bump-version.sh` reports "No commits found since last tag", make some commits first:

```bash
git commit -m "fix: your bug fix"
./bump-version.sh
```

### Version mismatch

If VERSION file and script have different versions:

```bash
# Check current values
cat VERSION
grep "^VERSION=" generate-docs-toc.sh

# Use bump-version to sync
./bump-version.sh $(cat VERSION)
```

### Forgot to create tag

If you committed a version bump but forgot to tag:

```bash
# Create tag for current version
VERSION=$(cat VERSION)
git tag -a "v${VERSION}" -m "Release version ${VERSION}"
git push --tags
```

## References

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
