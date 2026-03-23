#!/usr/bin/env bash

# =============================================================================
# File/Directory Creator Script
# =============================================================================
# DESCRIPTION: A robust Bash script to safely create files or directories.
#              Validates inputs, checks for existing targets, and supports dry-run.
#
# AUTHOR: [Your Name or GitHub Username]
# VERSION: 1.0
# LICENSE: MIT (or your preferred license)
#
# USAGE: ./create_fd.sh <f|d> <target> [--dry-run]
#        ./create_fd.sh -h
#
# FEATURES:
#   - Strict error handling with set -euo pipefail
#   - Input validation for type (f/d) and non-empty target
#   - Checks if target already exists
#   - Dry-run mode to preview actions
#   - Case-insensitive input handling
# =============================================================================

set -euo pipefail

dry_run=false

# =============================================================================
# HELP FUNCTION
# Displays usage information and exits
# =============================================================================
help() {
    echo "Usage: $(basename "$0") <f|d> <target> [--dry-run]"
    echo ""
    echo "Arguments:"
    echo "  f           Create a file"
    echo "  d           Create a directory"
    echo "  target      Path or name of the file/directory"
    echo "  --dry-run   Show what would happen without making changes"
    echo ""
    echo "Options:"
    echo "  -h          Display this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $(basename "$0") f myfile.txt          # Create file"
    echo "  $(basename "$0") d mydir               # Create directory"
    echo "  $(basename "$0") f /tmp/test.txt --dry-run  # Preview file creation"
}

# =============================================================================
# DRY-RUN DETECTION
# Checks if --dry-run flag is provided as third argument
# =============================================================================
if [[ "${3:-}" == "--dry-run" ]]; then
    dry_run=true
    set -- "$1" "$2"  # Remove dry-run arg from positional parameters
fi

# Handle help request first
if [[ "${1:-}" == "-h" ]]; then
    help
    exit 0
fi

# =============================================================================
# RUN FUNCTION
# Executes commands safely with dry-run support
# =============================================================================
run() {
    if [[ "$dry_run" == true ]]; then
        echo "[DRY RUN] Executing: $@"
    else
        "$@"
    fi
}

# =============================================================================
# ARGUMENT VALIDATION
# Ensures exactly 2 arguments are provided
# =============================================================================
validate_argument_count() {
    if [[ "$#" -ne 2 ]]; then
        echo "Error: Invalid number of arguments ($#)"
        echo "Usage: $0 <f|d> <target>"
        echo "-h for help"
        return 1
    fi
}

validate_argument_count "$@" || exit 1

type="$1"
target="$2"

# =============================================================================
# EMPTY INPUT VALIDATION
# Ensures both type and target are non-empty
# =============================================================================
validate_not_empty() {
    if [[ -z "$1" ]]; then
        echo "Error: $2 cannot be empty"
        return 1
    fi
}

validate_not_empty "$type" "Input type" || exit 1
validate_not_empty "$target" "Target path/name" || exit 1

# =============================================================================
# TARGET EXISTENCE CHECK
# Prevents overwriting existing files/directories
# =============================================================================
check_target() {
    if [[ -e "$1" ]]; then
        echo "Error: Target already exists -> $1"
        return 1
    fi
}

check_target "$target" || exit 1

# =============================================================================
# MAIN EXECUTION
# Creates file or directory based on input type
# =============================================================================
if [[ "$type" =~ ^[fF]$ ]]; then
    echo "Creating file: $target"
    run touch "$target"
elif [[ "$type" =~ ^[dD]$ ]]; then
    echo "Creating directory: $target"
    run mkdir -p "$target"
else
    echo "Error: Invalid input '$type'. Use 'f' for file or 'd' for directory."
    exit 1
fi

echo "✅ Done! Target '$target' successfully created."
