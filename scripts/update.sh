#!/bin/bash
#
# Updates OpenClaw and Ollama to latest versions.
#

echo "==================================="
echo " OpenClaw AI Hub — Update"
echo "==================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Update OpenClaw
echo "--- Updating OpenClaw ---"
CURRENT=$(openclaw --version 2>/dev/null || echo "not installed")
echo "Current version: $CURRENT"
npm update -g openclaw@latest
NEW=$(openclaw --version 2>/dev/null || echo "error")
echo "New version: $NEW"
echo ""

# Update Ollama
echo "--- Updating Ollama ---"
brew upgrade ollama 2>/dev/null || echo "Ollama already up to date"
echo ""

# Re-create MLX symlink (needed after Ollama updates on Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
    echo "Recreating MLX symlink (Apple Silicon)..."
    ln -sf /opt/homebrew/lib/libmlxc.dylib "$(dirname $(which ollama))/libmlxc.dylib" 2>/dev/null
    echo "Done."
fi
echo ""

# Restart gateway
echo "--- Restarting Gateway ---"
launchctl kickstart -k gui/$UID/ai.openclaw.gateway 2>/dev/null && echo "Gateway restarted" || echo "Could not restart gateway (may not be running as LaunchAgent)"
echo ""

# Run health check
echo "--- Running Health Check ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/health-check.sh"
