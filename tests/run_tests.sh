#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"

# Check if bats is installed
check_bats() {
    if ! command -v bats &> /dev/null; then
        echo -e "${RED}Error: bats is not installed${NC}"
        echo ""
        echo "Please install bats to run the test suite:"
        echo ""
        echo "  macOS (Homebrew):"
        echo "    brew install bats-core"
        echo ""
        echo "  Linux (apt):"
        echo "    sudo apt-get install bats"
        echo ""
        echo "  Linux (yum):"
        echo "    sudo yum install bats"
        echo ""
        echo "  From source:"
        echo "    git clone https://github.com/bats-core/bats-core.git"
        echo "    cd bats-core"
        echo "    sudo ./install.sh /usr/local"
        echo ""
        exit 1
    fi
}

# Check if parallel is installed (for parallel execution)
check_parallel() {
    if ! command -v parallel &> /dev/null; then
        echo -e "${YELLOW}Note: GNU parallel not found. Parallel execution disabled.${NC}"
        echo -e "${YELLOW}Install parallel for faster test execution:${NC}"
        echo ""
        echo "  macOS (Homebrew):"
        echo "    brew install parallel"
        echo ""
        echo "  Linux (apt):"
        echo "    sudo apt-get install parallel"
        echo ""
        echo "  Linux (yum):"
        echo "    sudo yum install parallel"
        echo ""
        return 1
    fi
    return 0
}

# Print usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TEST_FILE]

Run the test suite for generate-docs-toc.sh

OPTIONS:
    -h, --help           Show this help message
    -v, --verbose        Verbose output
    -t, --tap            Output in TAP format
    -f, --filter PATTERN Run only tests matching pattern
    -j, --jobs NUM       Run tests in parallel with NUM jobs (default: auto-detect CPUs)
    --no-parallel        Disable parallel execution
    --version            Show bats version

EXAMPLES:
    $(basename "$0")                          # Run all tests in parallel (auto-detect CPUs)
    $(basename "$0") test_generate_toc.bats   # Run specific test file
    $(basename "$0") -f "heading"             # Run tests matching "heading"
    $(basename "$0") -v                       # Run with verbose output
    $(basename "$0") -j 4                     # Run with 4 parallel jobs
    $(basename "$0") --no-parallel            # Run tests sequentially
EOF
    exit 0
}

# Auto-detect number of CPUs
detect_cpus() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n hw.ncpu
    else
        nproc
    fi
}

# Parse arguments
VERBOSE=""
TAP=""
FILTER=""
TEST_FILE=""
JOBS=$(detect_cpus)
PARALLEL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE="--verbose-run"
            shift
            ;;
        -t|--tap)
            TAP="--tap"
            shift
            ;;
        -f|--filter)
            FILTER="--filter $2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            PARALLEL=true
            shift 2
            ;;
        --no-parallel)
            PARALLEL=false
            shift
            ;;
        --version)
            bats --version
            exit 0
            ;;
        *.bats)
            TEST_FILE="$1"
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Set parallel execution flag
PARALLEL_FLAG=""
if [[ "$PARALLEL" == true ]]; then
    if check_parallel; then
        PARALLEL_FLAG="--jobs $JOBS"
    else
        PARALLEL=false
        echo ""
    fi
fi

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Documentation ToC Generator Tests${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    # Check bats installation
    check_bats

    # Show bats version
    echo -e "${YELLOW}Using bats version:${NC}"
    bats --version
    echo ""

    # Setup test environment
    echo -e "${YELLOW}Setting up test environment...${NC}"
    cd "$TEST_DIR"

    # Create output directory
    mkdir -p output

    # Run tests
    if [[ "$PARALLEL" == true ]]; then
        echo -e "${YELLOW}Running tests in parallel (${JOBS} jobs)...${NC}"
    else
        echo -e "${YELLOW}Running tests sequentially...${NC}"
    fi
    echo ""

    if [[ -n "$TEST_FILE" ]]; then
        # Run specific test file
        if [[ ! -f "$TEST_FILE" ]]; then
            echo -e "${RED}Error: Test file '$TEST_FILE' not found${NC}"
            exit 1
        fi
        bats $PARALLEL_FLAG $VERBOSE $TAP $FILTER "$TEST_FILE"
    else
        # Run all test files
        bats $PARALLEL_FLAG $VERBOSE $TAP $FILTER test_*.bats
    fi

    local exit_code=$?

    echo ""
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
    else
        echo -e "${RED}✗ Some tests failed${NC}"
    fi

    # Cleanup
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -rf output/*

    exit $exit_code
}

main "$@"
