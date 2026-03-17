#!/bin/bash

echo "==================================="
echo " OpenClaw AI Hub — Health Check"
echo "==================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

ok() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARNINGS=$((WARNINGS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ERRORS=$((ERRORS+1)); }

# --- OpenClaw Gateway ---
echo "--- Gateway ---"
if command -v openclaw &>/dev/null; then
    ok "OpenClaw installed: $(openclaw --version 2>/dev/null || echo 'version unknown')"
else
    fail "OpenClaw not installed"
fi

if pgrep -f "openclaw" &>/dev/null; then
    ok "Gateway process running"
else
    fail "Gateway process not running"
fi

# --- Ollama ---
echo ""
echo "--- Ollama ---"
if command -v ollama &>/dev/null; then
    ok "Ollama installed"
else
    fail "Ollama not installed"
fi

if curl -s http://localhost:11434/api/tags &>/dev/null; then
    ok "Ollama is running"
    # List models
    MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    for m in models:
        name = m.get('name', 'unknown')
        size_gb = m.get('size', 0) / 1073741824
        print(f'     - {name} ({size_gb:.1f} GB)')
except:
    print('     Could not parse model list')
" 2>/dev/null)
    if [ -n "$MODELS" ]; then
        echo "   Models:"
        echo "$MODELS"
    fi
else
    warn "Ollama not running. Start with: ollama serve"
fi

# --- Tailscale ---
echo ""
echo "--- Tailscale ---"
if command -v tailscale &>/dev/null; then
    TS_STATUS=$(tailscale status --json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    state = data.get('BackendState', 'Unknown')
    print(state)
except:
    print('Unknown')
" 2>/dev/null)
    if [ "$TS_STATUS" = "Running" ]; then
        TS_IP=$(tailscale ip -4 2>/dev/null)
        ok "Tailscale: Running (IP: ${TS_IP:-unknown})"
    else
        warn "Tailscale: ${TS_STATUS}"
    fi
else
    warn "Tailscale not installed (optional, needed for remote access)"
fi

# --- System ---
echo ""
echo "--- System ---"

# RAM
RAM_BYTES=$(sysctl -n hw.memsize)
RAM_GB=$((RAM_BYTES / 1073741824))
if [ "$RAM_GB" -ge 16 ]; then
    ok "RAM: ${RAM_GB} GB"
else
    warn "RAM: ${RAM_GB} GB (16+ GB recommended)"
fi

# Disk space
DISK_FREE=$(df -g / | tail -1 | awk '{print $4}')
if [ "$DISK_FREE" -ge 20 ]; then
    ok "Free disk space: ${DISK_FREE} GB"
else
    warn "Free disk space: ${DISK_FREE} GB (20+ GB recommended)"
fi

# Firewall
FW_STATUS=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
if [ "$FW_STATUS" -ge 1 ]; then
    ok "Firewall: enabled"
else
    warn "Firewall: disabled (enable in System Settings > Network > Firewall)"
fi

# FileVault
FV_STATUS=$(fdesetup status 2>/dev/null | grep -c "On" || echo "0")
if [ "$FV_STATUS" -ge 1 ]; then
    ok "FileVault: enabled"
else
    warn "FileVault: disabled (enable in System Settings > Privacy & Security)"
fi

# Session count
if [ -d ~/.openclaw/agents/main/sessions ]; then
    SESSION_COUNT=$(find ~/.openclaw/agents/main/sessions -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SESSION_COUNT" -gt 20 ]; then
        warn "Active sessions: ${SESSION_COUNT} (consider cleanup with scripts/session-cleanup.sh)"
    else
        ok "Active sessions: ${SESSION_COUNT}"
    fi
fi

# MEMORY.md size
if [ -f ~/.openclaw/workspace/MEMORY.md ]; then
    MEM_SIZE=$(wc -c < ~/.openclaw/workspace/MEMORY.md | tr -d ' ')
    if [ "$MEM_SIZE" -gt 16000 ]; then
        warn "MEMORY.md: ${MEM_SIZE} chars (over 16K limit — will be truncated!)"
    else
        ok "MEMORY.md: ${MEM_SIZE} chars"
    fi
fi

# --- Summary ---
echo ""
echo "==================================="
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}${ERRORS} error(s), ${WARNINGS} warning(s)${NC}"
    echo "Fix the errors above before relying on the system."
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}${WARNINGS} warning(s), no errors${NC}"
    echo "System is functional but could be improved."
    exit 0
else
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
fi
