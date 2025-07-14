#!/bin/bash

#########################################
# Swap Memory Manager
# 
# Author: Deba Protim Dey
# Email: debadey886@gmail.com
# Created: June 2025
# Version: 1.0
#
# Description: 
# This script monitors system memory usage and safely clears swap space
# when there's sufficient RAM available. Prevents system crashes by
# checking memory availability before swap operations.
#
# Usage: ./swap_manager.sh
#########################################

# Function to display memory info in human readable format
show_memory_status() {
    echo "========================================="
    echo "        SYSTEM MEMORY STATUS"
    echo "========================================="
}

# Get current free memory (available column from free command)
available_memory=$(free | grep '^Mem:' | awk '{print $7}')

# Get current swap usage
swap_used=$(free | grep '^Swap:' | awk '{print $3}')

# Display header
show_memory_status

# Show current memory and swap status with conversions
echo -e "Available Memory:\t${available_memory} kB ($(($available_memory / 1024)) MiB)"
echo -e "Swap in Use:\t\t${swap_used} kB ($(($swap_used / 1024)) MiB)"
echo "========================================="

# Check swap usage and take appropriate action
if [[ $swap_used -eq 0 ]]; then
    echo "✓ SUCCESS: No swap space is currently in use."
    echo "System is running efficiently with RAM only."
    
elif [[ $swap_used -lt $available_memory ]]; then
    echo "⚠ WARNING: Swap space is in use ($(($swap_used / 1024)) MiB)"
    echo "Available RAM is sufficient. Initiating swap cleanup..."
    echo ""
    
    # Safely clear swap space
    echo "Step 1: Disabling swap partitions..."
    sudo swapoff -a
    
    echo "Step 2: Re-enabling swap partitions..."
    sudo swapon -a
    
    echo "✓ SUCCESS: Swap space has been cleared successfully!"
    echo "System performance should improve."
    
else
    echo "✗ ERROR: Insufficient free memory to clear swap safely."
    echo "Current situation:"
    echo "  - Swap in use: $(($swap_used / 1024)) MiB"
    echo "  - Available RAM: $(($available_memory / 1024)) MiB"
    echo ""
    echo "Recommendation: Close some applications to free up memory first."
    exit 1
fi

echo "========================================="
echo "Operation completed. Script finished."
echo "========================================="
