#!/bin/bash

#############################################
# System Health Quick Check
#
# Author: Deba Protim Dey
# Email: debadey886@gmail.com
# Created: June 2025
# Version: 1.0
#
# Description:
# This script provides an immediate, on-screen overview of key system
# health indicators. It displays CPU, memory, disk usage, top processes,
# and basic network statistics for quick troubleshooting.
#
# Usage: ./system_health_check.sh
# Note: Some commands (e.g., dmesg, journalctl) may require 'sudo'.
#############################################

echo "========================================="
echo "      SYSTEM HEALTH QUICK CHECK"
echo "========================================="
echo ""
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Hostname: $(hostname)"
echo ""

# --- System Overview ---
echo "--- UPTIME AND LOAD AVERAGE ---"
uptime
echo ""

echo "--- MEMORY AND SWAP USAGE ---"
free -h
echo ""

echo "--- DISK USAGE ---"
df -h
echo ""

# --- Process & Resource Utilization ---
echo "--- TOP 10 CPU CONSUMING PROCESSES ---"
ps aux --sort=-%cpu | head -n 11 # Head includes header line
echo ""

echo "--- TOP 10 MEMORY CONSUMING PROCESSES ---"
ps aux --sort=-%mem | head -n 11 # Head includes header line
echo ""

echo "--- CURRENT RUNNING PROCESSES SNAPSHOT (TOP) ---"
top -b -n 1 | head -n 20 # Show top 20 lines for a quick overview
echo ""

# --- Network Status ---
echo "--- TOP 15 ESTABLISHED NETWORK CONNECTIONS ---"
ss -ant | head -n 16 # Head includes header line
echo ""

echo "--- NETWORK INTERFACE ERROR/DROP STATISTICS ---"
ip -s link show
echo ""

# --- System Logs (May require sudo) ---
echo "--- LAST 20 KERNEL MESSAGES (requires sudo) ---"
sudo dmesg -T | tail -n 20
echo ""

echo "--- LAST 20 SYSTEMD JOURNAL ENTRIES (requires sudo) ---"
sudo journalctl -n 20 --no-pager
echo ""

echo "========================================="
echo "            CHECK COMPLETE"
echo "========================================="
echo "Scroll up to review the output."
echo ""
