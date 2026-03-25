#!/usr/bin/env bash

# =============================================================================
# File Cleanup Script (find & delete)
# =============================================================================
# DESCRIPTION: Searches a directory for files based on age and size, 
#              with an optional dry-run flag to preview deletions.
#
# Author: Deba Protim Dey
# Email: debadey886@gmail.com
# Version: 1.0
#
# USAGE: ./cleanup.sh <target> <days> <size> [--dry-run]
# =============================================================================

# set -e: exit on error; -u: crash on unset vars; -o pipefail: catch pipe errors
set -euo pipefail

# Initialize dry_run state
dry_run=false

# =============================================================================
# HELP FUNCTION
# Displays usage instructions for the user
# =============================================================================
help() {
    echo "Usage: $(basename "$0") <target> <days> <size> [--dry-run]"
    echo ""
    echo "Arguments:"
    echo "  target    Directory to search"
    echo "  days      Age with +/- prefix"
    echo "  size      Size with +/- prefix and unit"
    echo ""
    echo "LOGIC GUIDE (+/-):"
    echo "  ------------------------------------------------------------"
    echo "  For DAYS (-mtime):"
    echo "    +7      Older than 7 days (Modified MORE than 7 days ago)"
    echo "    -7      Newer than 7 days (Modified WITHIN the last 7 days)"
    echo "     7      Exactly 7 days old"
    echo ""
    echo "  For SIZE (-size):"
    echo "    +100M   Larger than 100MB"
    echo "-100M   Smaller than 100MB"
    echo "     100M   Exactly 100MB"
    echo "  ------------------------------------------------------------"
    echo ""
    echo "UNITS:"
    echo "  k (Kilobytes), M (Megabytes), G (Gigabytes)"
    echo ""
    echo "EXAMPLE:"
    echo "  $(basename "$0") /var/log +30 +1G --dry-run"
}

# =============================================================================
# FLAG DETECTION
# Checks if --dry-run is in the 4th position and shifts parameters
# =============================================================================
if [[ "${4:-}" == "--dry-run" ]]; then
    dry_run=true
    set -- "$1" "$2" "$3"  # Remove dry-run arg from positional parameters
fi

# Handle help request
if [[ "${1:-}" == "-h" ]];then
        help
        exit 0
fi

# =============================================================================
# ARGUMENT VALIDATION
# Ensures exactly 3 arguments (target, days, size) are provided
# =============================================================================
validate_argument_count() {
    if [[ "$#" -ne 3 ]];then
        echo "Error: Invalid number of arguments ($#)"
        echo "Usage: $0 <target> <days> <size>"
        echo "-h for help"
        return 1
    fi
}

validate_argument_count "$@" || exit 1

# Assigning positional arguments to named variables
target="${1:-}"
days="${2:-}"
size="${3:-}"

# =============================================================================
# EMPTY VALUE VALIDATION
# Ensures required variables are not empty strings
# =============================================================================
validate_not_empty() {
        if [[ -z "$1" ]];then
           echo "Error: $2 cannot be empty"
           return 1
        fi
}

validate_not_empty "$target" "Target" || exit 1
validate_not_empty "$days" "Days" || exit 1
validate_not_empty "$size" "Size" || exit 1

# =============================================================================
# DIRECTORY VALIDATION
# Checks if the target path is a valid directory
# =============================================================================
check_target() {
    if [[ ! -d "$1" ]]; then
        echo "Error: Target doesn't exists -> $1"
        return 1
    fi
}

check_target "$target" || exit 1

# Build the command array for safe execution
cmd=(find "$target" -type f -mtime "$days" -size "$size")

# =============================================================================
# EXECUTION LOGIC
# Switches between printing files (Dry Run) and deleting files (Live)
# =============================================================================
if [[ "$dry_run" == true ]]; then
    echo "--- [DRY RUN] ---"
    "${cmd[@]}" -print
else
    echo "--- [LIVE DELETION] ---"
    # Note: Using -delete for final cleanup
    "${cmd[@]}" -delete
    echo "Done."
fi
