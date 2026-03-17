#!/bin/bash
# heartbeat-check.sh — Shell-only heartbeat for OpenClaw
# Kein LLM, kein OpenClaw, kein Hängen möglich.
# Triggered by: com.openclaw.heartbeat LaunchAgent (hourly, 07:00-22:00 local time)
#
# Checks:
#   1. Disk usage > 90% → Alert
#   2. Ollama nicht erreichbar → Alert
#
# Bei Fehler: curl → Telegram Direktnachricht
# Bei OK: exit 0, keine Nachricht

BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"

ERRORS=()

# 1. Disk-Check
DISK_PCT=$(df -h / | awk 'NR==2{gsub(/%/,""); print $5}')
if [ "${DISK_PCT:-0}" -ge 90 ]; then
    ERRORS+=("Disk: ${DISK_PCT}% belegt (>90%)")
fi

# 2. Ollama-Check
if ! curl -s --max-time 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
    ERRORS+=("Ollama: nicht erreichbar")
fi

# Ergebnis
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
