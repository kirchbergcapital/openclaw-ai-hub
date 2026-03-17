#!/bin/bash
#
# Cleans up stale OpenClaw sessions older than 2 hours.
# Run manually or via LaunchAgent (see launchagents/).
#

SESSION_DIR="$HOME/.openclaw/agents/main/sessions"
MAX_AGE_MIN=120  # 2 hours

if [ ! -d "$SESSION_DIR" ]; then
    echo "Session directory not found: $SESSION_DIR"
    exit 0
fi

# Count before cleanup
BEFORE=$(find "$SESSION_DIR" -name "*.jsonl" -type f 2>/dev/null | wc -l | tr -d ' ')

# Find and delete old sessions
DELETED=$(find "$SESSION_DIR" -name "*.jsonl" -mmin +${MAX_AGE_MIN} -type f -print -delete 2>/dev/null | wc -l | tr -d ' ')

echo "Session cleanup: ${DELETED} removed (${BEFORE} total, ${MAX_AGE_MIN}min threshold)"
