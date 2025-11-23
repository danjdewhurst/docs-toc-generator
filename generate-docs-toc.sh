#!/usr/bin/env bash

set -euo pipefail

# Configuration
DOCS_DIR="docs"
OUTPUT_FILE=""
SIMPLE_MODE=false

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate a table of contents for all documentation files.

OPTIONS:
    -o, --output FILE    Write output to FILE instead of stdout
    -s, --simple         Simple mode (only paths and titles, no metadata)
    -h, --help           Show this help message

EXAMPLES:
    $(basename "$0")                    # Print TOC to stdout
    $(basename "$0") -o docs/README.md  # Write TOC to file
    $(basename "$0") --simple           # Print simple TOC
EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -s|--simple)
                SIMPLE_MODE=true
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
    local max_chars=200
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

# Generate TOC content
generate_toc() {
    local output=""

    # Header
    output+="# Documentation Table of Contents\n\n"
    output+="Generated: $(date +%Y-%m-%d)\n\n"

    if [[ ! -d "$DOCS_DIR" ]]; then
        echo "Error: Documentation directory '$DOCS_DIR' not found" >&2
        exit 1
    fi

    # Count files
    local total_files=$(find "$DOCS_DIR" -type f | wc -l | tr -d ' ')
    local md_files=$(find "$DOCS_DIR" -type f -name "*.md" | wc -l | tr -d ' ')

    output+="**Total files:** $total_files ($md_files markdown files)\n\n"
    output+="---\n\n"

    # Process each directory
    output+="## 📁 Plans\n\n"
    if [[ -d "$DOCS_DIR/plans" ]]; then
        output+=$(process_directory "$DOCS_DIR/plans" "")
    fi
    output+="\n"

    output+="## 📁 Research\n\n"
    if [[ -d "$DOCS_DIR/research" ]]; then
        # Process top-level research files
        while IFS= read -r file; do
            output+=$(process_file "$file" "")
        done < <(find "$DOCS_DIR/research" -maxdepth 1 -type f -name "*.md" | sort)

        # Process sectors subdirectory
        if [[ -d "$DOCS_DIR/research/sectors" ]]; then
            output+="\n### 📂 Sectors\n\n"
            output+=$(process_directory "$DOCS_DIR/research/sectors" "")
        fi
    fi
    output+="\n"

    output+="## 📁 Sample Data\n\n"
    if [[ -d "$DOCS_DIR/sample-data" ]]; then
        output+=$(process_directory "$DOCS_DIR/sample-data" "")
    fi

    echo -e "$output"
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
        # Extract heading and snippet in one pass
        local result=$(get_heading_and_snippet "$file")
        IFS='|' read -r heading snippet <<< "$result"

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
            if [[ -n "$snippet" ]]; then
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

    output+="# Documentation Table of Contents\n\n"

    # Use tree-like structure
    while IFS= read -r file; do
        local rel_path="${file#./}"
        local depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
        local indent=""
        for ((i=0; i<depth-1; i++)); do
            indent+="  "
        done

        local filename=$(basename "$file")
        local extension="${filename##*.}"

        if [[ "$extension" == "md" ]]; then
            local result=$(get_heading_and_snippet "$file")
            IFS='|' read -r heading snippet <<< "$result"
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
    done < <(find "$DOCS_DIR" -type f | sort)

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
        echo "Table of contents generated: $OUTPUT_FILE"
    else
        echo -e "$toc_content"
    fi
}

main "$@"
