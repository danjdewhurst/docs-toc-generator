#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/VERSION"
SCRIPT_FILE="${SCRIPT_DIR}/generate-docs-toc.sh"
CHANGELOG_FILE="${SCRIPT_DIR}/CHANGELOG.md"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [VERSION_TYPE]

Bump version based on conventional commits or manually specify version.

VERSION_TYPE:
    major           Bump major version (X.0.0) - breaking changes
    minor           Bump minor version (x.Y.0) - new features
    patch           Bump patch version (x.y.Z) - bug fixes
    auto            Auto-detect based on conventional commits (default)
    X.Y.Z           Set specific version number

OPTIONS:
    -n, --dry-run   Show what would be done without making changes
    -t, --tag       Create git tag after version bump
    -p, --push      Push changes and tags to remote (implies --tag)
    -h, --help      Show this help message

EXAMPLES:
    $(basename "$0")                    # Auto-detect version bump
    $(basename "$0") minor              # Bump minor version
    $(basename "$0") 3.0.0              # Set specific version
    $(basename "$0") --tag              # Auto-detect and create tag
    $(basename "$0") -t -p              # Auto-detect, tag, and push

EOF
    exit 0
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        log_error "VERSION file not found"
        exit 1
    fi
}

get_last_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

parse_version() {
    local version="$1"
    local major minor patch

    if [[ "$version" =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        echo "$major $minor $patch"
    else
        log_error "Invalid version format: $version"
        exit 1
    fi
}

bump_version() {
    local current="$1"
    local bump_type="$2"

    read -r major minor patch <<< "$(parse_version "$current")"

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

detect_version_bump() {
    local last_tag="$1"
    local range

    if [[ -z "$last_tag" ]]; then
        range="HEAD"
    else
        range="${last_tag}..HEAD"
    fi

    local commits
    commits=$(git log "$range" --pretty=format:"%s" 2>/dev/null || echo "")

    if [[ -z "$commits" ]]; then
        log_warn "No commits found since last tag"
        echo "none"
        return
    fi

    local has_breaking=false
    local has_feat=false
    local has_fix=false

    while IFS= read -r commit; do
        if [[ "$commit" =~ BREAKING[[:space:]]CHANGE || "$commit" =~ ^[a-z]+\!: ]]; then
            has_breaking=true
        elif [[ "$commit" =~ ^feat(\(.+\))?: ]]; then
            has_feat=true
        elif [[ "$commit" =~ ^fix(\(.+\))?: ]]; then
            has_fix=true
        fi
    done <<< "$commits"

    if [[ "$has_breaking" == "true" ]]; then
        echo "major"
    elif [[ "$has_feat" == "true" ]]; then
        echo "minor"
    elif [[ "$has_fix" == "true" ]]; then
        echo "patch"
    else
        echo "patch"
    fi
}

get_commit_types() {
    local last_tag="$1"
    local range

    if [[ -z "$last_tag" ]]; then
        range="HEAD"
    else
        range="${last_tag}..HEAD"
    fi

    git log "$range" --pretty=format:"%s" 2>/dev/null | \
        grep -E "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?:" || true
}

update_changelog() {
    local new_version="$1"
    local last_tag="$2"
    local date
    date=$(date +%Y-%m-%d)

    local temp_file="${CHANGELOG_FILE}.tmp"
    local added=()
    local changed=()
    local fixed=()
    local deprecated=()
    local removed=()
    local security=()

    local range
    if [[ -z "$last_tag" ]]; then
        range="HEAD"
    else
        range="${last_tag}..HEAD"
    fi

    while IFS= read -r commit; do
        [[ -z "$commit" ]] && continue

        local type=""
        local scope=""
        local description=""

        # Match: type(scope): description or type: description
        if [[ "$commit" =~ ^([a-z]+) ]]; then
            type="${BASH_REMATCH[1]}"
            local rest="${commit#*:}"
            rest="${rest# }"

            # Extract scope if present: type(scope)
            case "$commit" in
                *\(*\)*)
                    # Extract text between parentheses using parameter expansion
                    local temp="${commit#*\(}"
                    scope="${temp%%\)*}"
                    description="${scope}: ${rest}"
                    ;;
                *)
                    description="$rest"
                    ;;
            esac

            case "$type" in
                feat)
                    added+=("$description")
                    ;;
                fix)
                    fixed+=("$description")
                    ;;
                docs|style|refactor)
                    changed+=("$description")
                    ;;
                perf)
                    changed+=("Performance: $description")
                    ;;
                test|ci|build|chore)
                    ;;
            esac
        fi
    done <<< "$(get_commit_types "$last_tag")"

    {
        head -n 6 "$CHANGELOG_FILE"
        echo ""
        echo "## [${new_version}] - ${date}"
        echo ""

        if [[ ${#added[@]} -gt 0 ]]; then
            echo "### Added"
            for item in "${added[@]}"; do
                echo "- ${item}"
            done
            echo ""
        fi

        if [[ ${#changed[@]} -gt 0 ]]; then
            echo "### Changed"
            for item in "${changed[@]}"; do
                echo "- ${item}"
            done
            echo ""
        fi

        if [[ ${#fixed[@]} -gt 0 ]]; then
            echo "### Fixed"
            for item in "${fixed[@]}"; do
                echo "- ${item}"
            done
            echo ""
        fi

        tail -n +7 "$CHANGELOG_FILE"
    } > "$temp_file"

    mv "$temp_file" "$CHANGELOG_FILE"
}

update_files() {
    local new_version="$1"

    echo "$new_version" > "$VERSION_FILE"
    log_info "Updated VERSION file to ${new_version}"

    sed -i.bak "s/^VERSION=\".*\"/VERSION=\"${new_version}\"/" "$SCRIPT_FILE"
    rm -f "${SCRIPT_FILE}.bak"
    log_info "Updated ${SCRIPT_FILE} to ${new_version}"
}

main() {
    local dry_run=false
    local create_tag=false
    local push_changes=false
    local version_type="auto"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -t|--tag)
                create_tag=true
                shift
                ;;
            -p|--push)
                push_changes=true
                create_tag=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            major|minor|patch|auto)
                version_type="$1"
                shift
                ;;
            [0-9]*.[0-9]*.[0-9]*)
                version_type="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi

    local current_version
    current_version=$(get_current_version)
    log_info "Current version: ${current_version}"

    local new_version
    local last_tag
    last_tag=$(get_last_tag)

    if [[ "$version_type" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        new_version="$version_type"
        log_info "Setting version to: ${new_version}"
    else
        if [[ "$version_type" == "auto" ]]; then
            version_type=$(detect_version_bump "$last_tag")
            if [[ "$version_type" == "none" ]]; then
                log_warn "No version bump needed"
                exit 0
            fi
            log_info "Auto-detected bump type: ${version_type}"
        fi

        new_version=$(bump_version "$current_version" "$version_type")
        log_info "Bumping ${version_type} version: ${current_version} → ${new_version}"
    fi

    if [[ "$new_version" == "$current_version" ]]; then
        log_warn "Version unchanged: ${current_version}"
        exit 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN - No changes will be made"
        echo ""
        echo "Would update:"
        echo "  - VERSION: ${current_version} → ${new_version}"
        echo "  - ${SCRIPT_FILE}: VERSION variable"
        echo "  - ${CHANGELOG_FILE}: Add new version section"
        if [[ "$create_tag" == "true" ]]; then
            echo "  - Git tag: v${new_version}"
        fi
        if [[ "$push_changes" == "true" ]]; then
            echo "  - Push to remote"
        fi
        exit 0
    fi

    update_files "$new_version"
    update_changelog "$new_version" "$last_tag"
    log_info "Updated CHANGELOG.md"

    git add "$VERSION_FILE" "$SCRIPT_FILE" "$CHANGELOG_FILE"
    git commit -m "chore: bump version to ${new_version}"
    log_info "Created commit for version ${new_version}"

    if [[ "$create_tag" == "true" ]]; then
        git tag -a "v${new_version}" -m "Release version ${new_version}"
        log_info "Created tag v${new_version}"
    fi

    if [[ "$push_changes" == "true" ]]; then
        git push
        git push --tags
        log_info "Pushed changes and tags to remote"
    fi

    echo ""
    echo -e "${BOLD}${GREEN}Version bumped successfully!${NC}"
    echo -e "New version: ${BOLD}${new_version}${NC}"

    if [[ "$create_tag" == "false" ]]; then
        echo ""
        log_warn "Don't forget to create a tag: git tag -a v${new_version} -m 'Release version ${new_version}'"
    fi

    if [[ "$push_changes" == "false" ]]; then
        echo ""
        log_warn "Don't forget to push: git push && git push --tags"
    fi
}

main "$@"
