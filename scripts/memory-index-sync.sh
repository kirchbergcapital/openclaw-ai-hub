#!/bin/bash
# memory-index-sync.sh — Checks and re-indexes OpenClaw memory if dirty
# No LLM. No OpenClaw agent. Direct CLI call only.
# Triggered by: com.openclaw.memory-index-sync LaunchAgent (hourly + RunAtLoad)

LOG="$HOME/.openclaw/workspace/logs/memory-index-sync.log"
mkdir -p "$(dirname "$LOG")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] memory-index-sync: checking..." >> "$LOG"

# Check if openclaw CLI is available
if ! command -v openclaw &>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: openclaw not found in PATH" >> "$LOG"
    exit 1
fi

# Check memory status
STATUS=$(openclaw memory status 2>&1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] status: $STATUS" >> "$LOG"

# Re-index if dirty, unsynced, or error detected
if echo "$STATUS" | grep -qiE "dirty|unsynced|error|out of date|stale"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dirty/unsynced detected — running force index..." >> "$LOG"
    openclaw memory index --force >> "$LOG" 2>&1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Re-index complete." >> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index OK — no action needed." >> "$LOG"
fi

exit 0
