#!/usr/bin/env bash

# =============================================================================
# Bulk File Renamer Script
# =============================================================================
# DESCRIPTION: Safely appends a suffix to files with a specific extension.
#              Includes collision detection and a robust dry-run mode.
#
# Author: Deba Protim Dey
# Email: debadey886@gmail.com
# Version: 1.1
#
# USAGE: ./bulk_rename.sh <extension> <suffix> [--dry-run]
#        ./bulk_rename.sh -h
# =============================================================================
#!/usr/bin/env bash
set -euo pipefail
# Enable nullglob: if no files match, the loop won't run (prevents '*.jpg' literal errors)
shopt -s nullglob
dry_run=false

# =============================================================================
# HELP FUNCTION
# =============================================================================
help() {
        echo "Usage: $(basename "$0") <extension> <suffix> [--dry-run]"
        echo ""
        echo "Arguments:"
        echo "extension   Provide an extension"
        echo "suffix      Provide a suffix for renaming"
        echo "--dry-run   Show what would happen without making changes"
        echo ""
        echo "Options:"
        echo "-h        Display this help message"
        echo ""
        echo "EXAMPLES:"
        echo "$(basename "$0") txt backup          # rename files"
        echo "$(basename "$0") txt backup --dry-run  # Preview file creation"

}

# =============================================================================
# DRY-RUN DETECTION
# Checks if --dry-run flag is provided as third argument
# =============================================================================

if [[ "${3:-}" == "--dry-run" ]];then
        dry_run=true
        set -- "$1" "$2"  # Remove dry-run arg from positional parameters
fi

# Handle help request first
if [[ "${1:-}" == "-h" ]];then
        help
        exit 0
fi

# =============================================================================
# RUN FUNCTION
# Executes commands safely with dry-run support
# =============================================================================
run() {
    if [[ "$dry_run" == true ]];then
        printf '[DRY RUN] '
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# =============================================================================
# ARGUMENT VALIDATION
# Ensures exactly 2 arguments are provided
# =============================================================================
validate_argument_count() {
        if [[ "$#" -ne 2 ]];then
           echo "Error: Invalid number of arguments ($#)"
           echo "Usage: $0 <extension> <suffix>"
           echo "-h for help"
           return 1
        fi
}

validate_argument_count "$@" || exit 1

ext="$1"
suffix="$2"

# =============================================================================
# EMPTY INPUT VALIDATION
# Ensures both extension and suffix are non-empty
# =============================================================================
validate_not_empty() {
        if [[ -z "$1" ]];then
           echo "Error: $2 cannot be empty"
           return 1
        fi
}

validate_not_empty "$ext" "Extension" || exit 1
validate_not_empty "$suffix" "Suffix" || exit 1

# =============================================================================
# MAIN EXECUTION
# Rename file based on input extension and suffix
# =============================================================================
found=0
for file in *."$ext"; do
        found=1
        # Strip extension, add suffix, re-add extension
        new_name="${file%.*}_$suffix.$ext"
        # Collision check: Don't overwrite existing files
        if [[ -e "$new_name" ]]; then
            echo "Skipping: '$new_name' already exists!"
            continue
        fi
        # Run the move
        run mv "$file" "$new_name"
        if [[ "$dry_run" == true ]]; then
            echo "[DRY RUN] '$file' -> '$new_name'"
        else
            echo "Renamed: '$file' -> '$new_name'"
        fi
done

if [[ "$found" -eq 0 ]]; then
    if [[ "$dry_run" == true ]]; then
        echo "[DRY RUN] No *.$ext files found."
    else
        echo "No *.$ext files found."
    fi
    exit 0
fi

if [[ "$dry_run" == true ]]; then
    echo "✅ Dry run complete. No files were modified."
else
    echo "Done ✅"
fi
