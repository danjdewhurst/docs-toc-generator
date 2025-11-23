#!/usr/bin/env bash

set -euo pipefail

# Configuration
DOCS_DIR="docs"
OUTPUT_FILE=""
SIMPLE_MODE=false
SNIPPET_LENGTH=200
MAX_DEPTH=""
SORT_BY="name"
EXCLUDE_PATTERNS=()
INCLUDE_PATTERNS=()
NO_SNIPPETS=false
TOC_TITLE="Documentation Table of Contents"
GROUP_BY="directory"
QUIET=false

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate a table of contents for all documentation files.

OPTIONS:
    -d, --directory DIR       Documentation directory to scan (default: docs)
    -o, --output FILE         Write output to FILE instead of stdout
    -s, --simple              Simple mode (only paths and titles, no metadata)
    -l, --snippet-length NUM  Maximum snippet length in characters (default: 200)
    --max-depth NUM           Maximum directory depth to traverse (default: unlimited)
    --sort [name|date|size]   Sort files by name, date, or size (default: name)
    -e, --exclude PATTERN     Exclude files/dirs matching pattern (can be used multiple times)
    -i, --include PATTERN     Only include files matching pattern (can be used multiple times)
    --no-snippets             Disable snippet extraction for faster processing
    --title TEXT              Custom title for table of contents
    --group-by [directory|type|none]  How to group files (default: directory)
    -q, --quiet               Suppress progress messages
    -h, --help                Show this help message

EXAMPLES:
    $(basename "$0")                                    # Print TOC to stdout
    $(basename "$0") -d documentation -o TOC.md         # Custom directory and output
    $(basename "$0") --simple --no-snippets             # Minimal output
    $(basename "$0") -e "*.draft.md" -e "tmp/"          # Exclude patterns
    $(basename "$0") --max-depth 2 --sort date          # Limit depth, sort by date
    $(basename "$0") -i "*.md" --title "API Docs"       # Only markdown, custom title
EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--directory)
                DOCS_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -s|--simple)
                SIMPLE_MODE=true
                shift
                ;;
            -l|--snippet-length)
                SNIPPET_LENGTH="$2"
                shift 2
                ;;
            --max-depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            --sort)
                SORT_BY="$2"
                if [[ ! "$SORT_BY" =~ ^(name|date|size)$ ]]; then
                    echo "Error: --sort must be 'name', 'date', or 'size'" >&2
                    exit 1
                fi
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            -i|--include)
                INCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --no-snippets)
                NO_SNIPPETS=true
                shift
                ;;
            --title)
                TOC_TITLE="$2"
                shift 2
                ;;
            --group-by)
                GROUP_BY="$2"
                if [[ ! "$GROUP_BY" =~ ^(directory|type|none)$ ]]; then
                    echo "Error: --group-by must be 'directory', 'type', or 'none'" >&2
                    exit 1
                fi
                shift 2
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                echo "Use -h or --help for usage information" >&2
                exit 1
                ;;
        esac
    done
}

# Strip markdown formatting from text
strip_markdown() {
    local text="$1"

    # Use a single sed call with multiple expressions for efficiency
    text=$(sed -e 's/\*\*\([^*]*\)\*\*/\1/g' \
               -e 's/\*\([^*]*\)\*/\1/g' \
               -e 's/__\([^_]*\)__/\1/g' \
               -e 's/_\([^_]*\)_/\1/g' \
               -e 's/`\([^`]*\)`/\1/g' \
               -e 's/\[\([^]]*\)\]([^)]*)/\1/g' \
               -e 's/<[^>]*>//g' <<< "$text")

    echo "$text"
}

# Extract heading and snippet from file in a single pass
get_heading_and_snippet() {
    local file="$1"
    local max_chars="$SNIPPET_LENGTH"
    local heading=""
    local snippet=""
    local found_heading=false
    local collecting_snippet=false
    local collected=""
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Extract heading from first few lines
        if [[ $found_heading == false ]]; then
            if [[ "$line" =~ ^#\ (.+)$ ]]; then
                heading="${BASH_REMATCH[1]}"
                # Strip markdown from heading using bash parameter expansion
                heading="${heading//\*\*/}"
                heading="${heading//\*/}"
                heading="${heading//\`/}"
                heading="${heading//_/}"
                found_heading=true
                collecting_snippet=true
                continue
            elif [[ "$line" =~ ^##\ (.+)$ ]]; then
                heading="${BASH_REMATCH[1]}"
                heading="${heading//\*\*/}"
                heading="${heading//\*/}"
                heading="${heading//\`/}"
                heading="${heading//_/}"
                found_heading=true
                collecting_snippet=true
                continue
            else
                # Start collecting snippet from line 1 if no heading found yet
                collecting_snippet=true
            fi
        fi

        # Extract snippet
        if [[ $collecting_snippet == true ]]; then
            if [[ ${#collected} -ge $max_chars ]]; then
                break
            fi

            # Skip empty lines
            if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]]; then
                continue
            fi

            # Skip horizontal rules
            if [[ "$line" =~ ^---+$ ]]; then
                continue
            fi

            # Skip metadata lines and headings
            if [[ "$line" =~ ^[-*] || "$line" =~ ^[0-9]+\. || "$line" =~ ^\*\*.*:\*\* || "$line" =~ ^#+ ]]; then
                continue
            fi

            # Clean the line
            local clean_line="$line"

            # Quick check if line needs cleaning
            if [[ "$clean_line" =~ [\*_\`\[\<] ]]; then
                clean_line=$(strip_markdown "$clean_line")
            fi

            # Skip if cleaned line is empty
            if [[ -z "$clean_line" || "$clean_line" =~ ^[[:space:]]*$ ]]; then
                continue
            fi

            collected="$collected $clean_line"
        fi

    done < "$file"

    # Trim whitespace from snippet
    snippet="${collected#"${collected%%[![:space:]]*}"}"
    snippet="${snippet%"${snippet##*[![:space:]]}"}"

    if [[ ${#snippet} -gt $max_chars ]]; then
        snippet="${snippet:0:$max_chars}..."
    fi

    echo "$heading|$snippet"
}

# Format file size in human readable format
format_size() {
    local size=$1
    if (( size < 1024 )); then
        echo "${size}B"
    elif (( size < 1048576 )); then
        echo "$(( size / 1024 ))KB"
    else
        echo "$(( size / 1048576 ))MB"
    fi
}

# Get file metadata (size and date) in one call
get_file_metadata() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f "%z|%Sm" -t "%Y-%m-%d" "$file"
    else
        local size=$(stat -c "%s" "$file")
        local date=$(stat -c "%y" "$file" | cut -d' ' -f1)
        echo "${size}|${date}"
    fi
}

# Check if file should be included based on include/exclude patterns
should_include_file() {
    local file="$1"
    local basename_file=$(basename "$file")

    # Check exclude patterns
    if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$file" == *"$pattern"* ]] || [[ "$basename_file" == $pattern ]]; then
                return 1
            fi
        done
    fi

    # Check include patterns (if any specified)
    if [[ ${#INCLUDE_PATTERNS[@]} -gt 0 ]]; then
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            if [[ "$file" == *"$pattern"* ]] || [[ "$basename_file" == $pattern ]]; then
                return 0
            fi
        done
        return 1
    fi

    return 0
}

# Get sorted list of files
get_sorted_files() {
    local dir="$1"
    local depth_arg=""

    if [[ -n "$MAX_DEPTH" ]]; then
        depth_arg="-maxdepth $MAX_DEPTH"
    fi

    case "$SORT_BY" in
        name)
            find "$dir" $depth_arg -type f 2>/dev/null | sort
            ;;
        date)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                find "$dir" $depth_arg -type f 2>/dev/null -exec stat -f "%m %N" {} \; | sort -rn | cut -d' ' -f2-
            else
                find "$dir" $depth_arg -type f 2>/dev/null -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2-
            fi
            ;;
        size)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                find "$dir" $depth_arg -type f 2>/dev/null -exec stat -f "%z %N" {} \; | sort -rn | cut -d' ' -f2-
            else
                find "$dir" $depth_arg -type f 2>/dev/null -printf "%s %p\n" | sort -rn | cut -d' ' -f2-
            fi
            ;;
    esac
}

# Generate TOC content
generate_toc() {
    local output=""

    # Header
    output+="# $TOC_TITLE\n\n"
    output+="Generated: $(date +%Y-%m-%d)\n\n"

    if [[ ! -d "$DOCS_DIR" ]]; then
        echo "Error: Documentation directory '$DOCS_DIR' not found" >&2
        exit 1
    fi

    # Get all files
    local all_files=()
    while IFS= read -r file; do
        if should_include_file "$file"; then
            all_files+=("$file")
        fi
    done < <(get_sorted_files "$DOCS_DIR")

    # Count files
    local total_files=${#all_files[@]}
    local md_files=0
    for file in "${all_files[@]}"; do
        if [[ "$file" == *.md ]]; then
            ((md_files++))
        fi
    done

    output+="**Total files:** $total_files ($md_files markdown files)\n\n"
    output+="---\n\n"

    # Generate output based on GROUP_BY option
    case "$GROUP_BY" in
        directory)
            output+=$(generate_by_directory "${all_files[@]}")
            ;;
        type)
            output+=$(generate_by_type "${all_files[@]}")
            ;;
        none)
            output+=$(generate_flat "${all_files[@]}")
            ;;
    esac

    echo -e "$output"
}

# Generate TOC grouped by directory
generate_by_directory() {
    local files=("$@")
    local output=""
    local current_dir=""
    local depth=0

    for file in "${files[@]}"; do
        local file_dir=$(dirname "$file")
        local rel_dir="${file_dir#$DOCS_DIR}"
        rel_dir="${rel_dir#/}"

        if [[ "$file_dir" != "$current_dir" ]]; then
            current_dir="$file_dir"
            if [[ -n "$rel_dir" ]]; then
                depth=$(echo "$rel_dir" | tr -cd '/' | wc -c)
                local dir_name=$(basename "$file_dir")
                dir_name=$(echo "$dir_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')

                if [[ $depth -eq 0 ]]; then
                    output+="\n## 📁 $dir_name\n\n"
                else
                    local heading=$(printf '###%.0s' $(seq 1 $((depth + 2))))
                    output+="\n$heading 📂 $dir_name\n\n"
                fi
            fi
        fi
        output+=$(process_file "$file" "")
    done

    echo "$output"
}

# Generate TOC grouped by file type
generate_by_type() {
    local files=("$@")
    local output=""
    local extensions=()
    local ext

    # Get unique extensions
    for file in "${files[@]}"; do
        if [[ "$file" == *.* ]]; then
            ext="${file##*.}"
        else
            ext="no-extension"
        fi

        # Check if extension already in list
        local found=false
        if [[ ${#extensions[@]} -gt 0 ]]; then
            for existing_ext in "${extensions[@]}"; do
                if [[ "$existing_ext" == "$ext" ]]; then
                    found=true
                    break
                fi
            done
        fi

        if [[ "$found" == false ]]; then
            extensions+=("$ext")
        fi
    done

    # Sort extensions
    IFS=$'\n' extensions=($(sort <<<"${extensions[*]}"))
    unset IFS

    # Output each type group
    for ext in "${extensions[@]}"; do
        local type_name="$ext"
        if [[ "$ext" == "no-extension" ]]; then
            type_name="No Extension"
        else
            type_name=$(echo "$ext" | tr '[:lower:]' '[:upper:]')
        fi

        output+="\n## 📄 $type_name Files\n\n"

        # Process files of this type
        for file in "${files[@]}"; do
            local file_ext
            if [[ "$file" == *.* ]]; then
                file_ext="${file##*.}"
            else
                file_ext="no-extension"
            fi

            if [[ "$file_ext" == "$ext" ]]; then
                output+=$(process_file "$file" "")
            fi
        done
    done

    echo "$output"
}

# Generate flat TOC (no grouping)
generate_flat() {
    local files=("$@")
    local output=""

    for file in "${files[@]}"; do
        output+=$(process_file "$file" "")
    done

    echo "$output"
}

# Process a directory
process_directory() {
    local dir="$1"
    local indent="$2"
    local output=""

    while IFS= read -r file; do
        output+=$(process_file "$file" "$indent")
    done < <(find "$dir" -maxdepth 1 -type f | sort)

    echo "$output"
}

# Process a single file
process_file() {
    local file="$1"
    local indent="$2"
    local output=""
    local filename=$(basename "$file")
    local extension="${filename##*.}"

    # Get relative path from project root
    local rel_path="$file"

    # Format the line based on file type
    if [[ "$extension" == "md" ]]; then
        local heading=""
        local snippet=""

        # Extract heading and snippet (unless NO_SNIPPETS is set)
        if [[ "$NO_SNIPPETS" == true ]]; then
            # Only extract heading, skip snippet for performance
            while IFS= read -r line; do
                if [[ "$line" =~ ^#\ (.+)$ ]] || [[ "$line" =~ ^##\ (.+)$ ]]; then
                    heading="${BASH_REMATCH[1]}"
                    heading="${heading//\*\*/}"
                    heading="${heading//\*/}"
                    heading="${heading//\`/}"
                    heading="${heading//_/}"
                    break
                fi
            done < "$file"
        else
            local result=$(get_heading_and_snippet "$file")
            IFS='|' read -r heading snippet <<< "$result"
        fi

        local title="${filename%.md}"

        # Use heading if found, otherwise use filename
        if [[ -n "$heading" ]]; then
            title="$heading"
        else
            # Convert filename to title case
            title=$(echo "$title" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        fi

        if [[ "$SIMPLE_MODE" == true ]]; then
            output+="${indent}- [$title]($rel_path)\n"
        else
            # Get metadata in one call
            local metadata=$(get_file_metadata "$file")
            IFS='|' read -r size mod_date <<< "$metadata"
            local formatted_size=$(format_size "$size")

            output+="${indent}- **[$title]($rel_path)**  \n"
            if [[ -n "$snippet" && "$NO_SNIPPETS" == false ]]; then
                output+="${indent}  ${snippet}  \n"
            fi
            output+="${indent}  *${formatted_size} • Modified: ${mod_date}*\n\n"
        fi
    else
        # Non-markdown files
        local title="$filename"
        if [[ "$SIMPLE_MODE" == true ]]; then
            output+="${indent}- [$title]($rel_path)\n"
        else
            local metadata=$(get_file_metadata "$file")
            IFS='|' read -r size mod_date <<< "$metadata"
            local formatted_size=$(format_size "$size")
            output+="${indent}- **$title**  \n"
            output+="${indent}  *${formatted_size}*\n\n"
        fi
    fi

    echo "$output"
}

# Generate simple TOC
generate_simple_toc() {
    local output=""

    output+="# $TOC_TITLE\n\n"

    if [[ ! -d "$DOCS_DIR" ]]; then
        echo "Error: Documentation directory '$DOCS_DIR' not found" >&2
        exit 1
    fi

    # Use tree-like structure with filtering and sorting
    while IFS= read -r file; do
        if ! should_include_file "$file"; then
            continue
        fi

        local rel_path="${file#./}"
        local depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
        local indent=""
        for ((i=0; i<depth-1; i++)); do
            indent+="  "
        done

        local filename=$(basename "$file")
        local extension="${filename##*.}"

        if [[ "$extension" == "md" ]]; then
            local heading=""

            # Only extract heading for markdown files
            while IFS= read -r line; do
                if [[ "$line" =~ ^#\ (.+)$ ]] || [[ "$line" =~ ^##\ (.+)$ ]]; then
                    heading="${BASH_REMATCH[1]}"
                    heading="${heading//\*\*/}"
                    heading="${heading//\*/}"
                    heading="${heading//\`/}"
                    heading="${heading//_/}"
                    break
                fi
            done < "$file"

            local title="${filename%.md}"

            if [[ -n "$heading" ]]; then
                title="$heading"
            else
                # Convert filename to title case
                title=$(echo "$title" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
            fi

            output+="${indent}- [$title]($rel_path)\n"
        else
            output+="${indent}- [$filename]($rel_path)\n"
        fi
    done < <(get_sorted_files "$DOCS_DIR")

    echo -e "$output"
}

# Main function
main() {
    parse_args "$@"

    local toc_content=""

    if [[ "$SIMPLE_MODE" == true ]]; then
        toc_content=$(generate_simple_toc)
    else
        toc_content=$(generate_toc)
    fi

    # Output to file or stdout
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo -e "$toc_content" > "$OUTPUT_FILE"
        if [[ "$QUIET" == false ]]; then
            echo "Table of contents generated: $OUTPUT_FILE"
        fi
    else
        echo -e "$toc_content"
    fi
}

main "$@"
