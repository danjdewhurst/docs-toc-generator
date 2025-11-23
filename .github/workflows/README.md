# GitHub Actions Workflows

This directory contains automated workflows for the Documentation ToC Generator project.

## Workflows

### 1. Test Suite (`test.yml`)

**Triggers:**
- Push to `main` branch
- Pull requests targeting `main`

**What it does:**
- Installs Bats and GNU Parallel
- Runs all 148 tests in parallel
- Reports pass/fail status

**Duration:** ~10-15 seconds (including setup)

**Status:**
- ✅ Required check for PRs
- 🔴 PR merge blocked if tests fail

### 2. Update Documentation ToC (`update-toc.yml`)

**Triggers:**
- Push to `main` branch
- Changes in `docs/**` (except `docs/README.md`)

**What it does:**
- Generates updated table of contents for docs
- Auto-commits changes if ToC changed
- Skips if commit message contains `[skip-toc]`

**Duration:** ~5-10 seconds

**Features:**
- Only commits if ToC actually changed
- Uses GitHub Actions bot for commits
- Adds `[skip-ci]` to avoid infinite loops

## Local Testing

Before pushing, run tests locally:

```bash
cd tests
./run_tests.sh
```

## Skipping Workflows

**Skip tests:**
```bash
git commit -m "docs: update readme [skip-ci]"
```

**Skip ToC generation:**
```bash
git commit -m "docs: add content [skip-toc]"
```

## Workflow Status

View workflow runs at:
```
https://github.com/danjdewhurst/docs-toc-generator/actions
```

## Troubleshooting

### Tests failing in CI but passing locally

1. Check Ubuntu vs macOS differences
2. Verify Bats and Parallel versions
3. Check file permissions
4. Review workflow logs

### ToC not updating

1. Verify changes are in `docs/**`
2. Check for `[skip-toc]` in commit message
3. Ensure workflow has write permissions
4. Review workflow logs

## Maintenance

Both workflows use:
- `ubuntu-latest` (currently Ubuntu 22.04)
- `actions/checkout@v4`
- Latest stable versions of Bats and Parallel

Update checkout action periodically:
```bash
# Check for updates
gh api repos/actions/checkout/releases/latest
```
