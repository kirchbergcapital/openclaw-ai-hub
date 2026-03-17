#!/bin/bash
# safari-cleanup.sh — Kills Safari and WebKit processes nightly
# Run via LaunchAgent: daily at 22:15
# No LLM. No OpenClaw. Pure shell.
#
# WHY: Safari tabs stay alive as separate WebKit processes even when the screen
# is locked. On a 24GB machine running Ollama, 10+ open tabs = 2-4GB RAM gone.
# This script reclaims that RAM before overnight tasks run.

LOG="$HOME/.openclaw/workspace/logs/safari-cleanup.log"
mkdir -p "$(dirname "$LOG")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# Gracefully quit Safari
if pgrep -x "Safari" > /dev/null; then
    osascript -e 'quit app "Safari"' 2>/dev/null
    sleep 3
    echo "[$TIMESTAMP] Safari quit" >> "$LOG"
else
    echo "[$TIMESTAMP] Safari was not running" >> "$LOG"
fi

# Kill remaining WebKit processes
WEBKIT_COUNT=$(pgrep -c "com.apple.WebKit" 2>/dev/null || echo 0)
if [ "$WEBKIT_COUNT" -gt 0 ]; then
    pkill -f "com.apple.WebKit" 2>/dev/null
    echo "[$TIMESTAMP] Killed $WEBKIT_COUNT WebKit processes" >> "$LOG"
fi

# Clean up SafariConfigura background service
pkill -f "SafariConfigura" 2>/dev/null

echo "[$TIMESTAMP] Safari cleanup complete" >> "$LOG"
