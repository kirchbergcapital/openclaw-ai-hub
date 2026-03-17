#!/bin/bash
set -e

echo "==================================="
echo " OpenClaw AI Hub — Installation"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}OK${NC} $1"; }
warn() { echo -e "${YELLOW}WARN${NC} $1"; }
fail() { echo -e "${RED}FAIL${NC} $1"; exit 1; }

# Check: Running as non-root
if [ "$EUID" -eq 0 ]; then
    fail "Do not run as root. Use a standard user account."
fi

# Check: macOS
if [[ "$(uname)" != "Darwin" ]]; then
    fail "This script is for macOS only."
fi

echo "--- Phase 1: Prerequisites ---"
echo ""

# Check: Homebrew
if command -v brew &>/dev/null; then
    ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"
else
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    fi
    ok "Homebrew installed"
fi

# Check: Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ]; then
        ok "Node.js v${NODE_VER}"
    else
        warn "Node.js v${NODE_VER} is old. Installing latest..."
        brew install node
        ok "Node.js updated to $(node --version)"
    fi
else
    warn "Node.js not found. Installing..."
    brew install node
    ok "Node.js $(node --version) installed"
fi

echo ""
echo "--- Phase 2: Ollama ---"
echo ""

# Install Ollama
if command -v ollama &>/dev/null; then
    ok "Ollama already installed"
else
    warn "Installing Ollama..."
    brew install ollama
    ok "Ollama installed"
fi

# Start Ollama
if curl -s http://localhost:11434/api/tags &>/dev/null; then
    ok "Ollama is running"
else
    warn "Starting Ollama..."
    ollama serve &>/dev/null &
    sleep 3
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        ok "Ollama started"
    else
        warn "Could not start Ollama. You may need to start it manually: ollama serve"
    fi
fi

# Check RAM and suggest models
RAM_BYTES=$(sysctl -n hw.memsize)
RAM_GB=$((RAM_BYTES / 1073741824))
echo ""
echo "Detected RAM: ${RAM_GB} GB"

# Note: Shell-based heartbeat (LaunchAgent) is recommended — no LLM needed for heartbeats.
# qwen2.5:3b is a useful lightweight model for simple sub-agent tasks, not heartbeat.

if [ "$RAM_GB" -ge 64 ]; then
    echo "Pulling recommended models for ${RAM_GB}GB..."
    ollama pull mistral-small:22b
    ollama pull qwen2.5-coder:14b
    ollama pull qwen2.5:3b
    ok "All recommended models pulled"
elif [ "$RAM_GB" -ge 24 ]; then
    echo "Pulling recommended models for ${RAM_GB}GB..."
    ollama pull mistral-small:22b
    ollama pull qwen2.5:3b
    ok "Recommended models pulled"
elif [ "$RAM_GB" -ge 16 ]; then
    echo "Pulling lightweight models for ${RAM_GB}GB..."
    ollama pull qwen2.5:3b
    ollama pull mistral:7b
    ok "Lightweight models pulled. Pull mistral-small:22b later if you need more capability."
else
    warn "Less than 16GB RAM. Local models will be limited. Consider using cloud API only."
fi

echo ""
echo "--- Phase 3: OpenClaw ---"
echo ""

# Install OpenClaw
if command -v openclaw &>/dev/null; then
    ok "OpenClaw already installed ($(openclaw --version 2>/dev/null || echo 'unknown version'))"
    echo "To update: npm update -g openclaw@latest"
else
    echo "Installing OpenClaw..."
    npm install -g openclaw@latest
    ok "OpenClaw installed"
fi

echo ""
echo "==================================="
echo " Installation complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Run the setup wizard:"
echo "     openclaw onboard --install-daemon"
echo ""
echo "  2. You'll need:"
echo "     - Anthropic API key (from console.anthropic.com)"
echo "     - Telegram bot token (from @BotFather)"
echo ""
echo "  3. After setup, test with:"
echo "     ./scripts/health-check.sh"
echo ""
echo "  4. Read the full guide: docs/SETUP.md"
echo ""
