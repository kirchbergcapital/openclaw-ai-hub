#!/bin/bash
# heartbeat-check.sh — Shell-only heartbeat for OpenClaw
# No LLM, no OpenClaw agent, no hang possible.
# Triggered by: com.openclaw.heartbeat LaunchAgent (hourly, 07:00-21:00 local time)
#
# Checks:
#   1. Disk usage > 90% -> Alert
#   2. Ollama not reachable -> Alert
#
# On error: curl -> Telegram alert
# On OK: exit 0, silent
#
# Credentials: Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in the LaunchAgent plist
# (EnvironmentVariables block) or in ~/.openclaw/.env as fallback.

# Load credentials — plist EnvironmentVariables take priority, .env as fallback
if [ -z "$TELEGRAM_BOT_TOKEN" ] && [ -f "$HOME/.openclaw/.env" ]; then
    source "$HOME/.openclaw/.env"
fi

BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"

ERRORS=()

# 1. Disk check
DISK_PCT=$(df -h / | awk 'NR==2{gsub(/%/,""); print $5}')
if [ "${DISK_PCT:-0}" -ge 90 ]; then
    ERRORS+=("Disk: ${DISK_PCT}% used (>90%)")
fi

# 2. Ollama check
if ! curl -s --max-time 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
    ERRORS+=("Ollama: not reachable")
fi

# Result
if [ ${#ERRORS[@]} -gt 0 ]; then
    MSG="⚠️ OpenClaw Heartbeat Alert:%0A"
    for ERR in "${ERRORS[@]}"; do
        MSG+="• ${ERR}%0A"
    done
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${MSG}" \
        -d "parse_mode=HTML" \
        > /dev/null 2>&1
    exit 1
fi

exit 0
