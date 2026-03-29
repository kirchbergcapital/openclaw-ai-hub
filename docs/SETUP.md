# Complete Setup Guide

**Time needed:** ~2 hours for the full setup

**What you need:**
- A dedicated Mac (Mac Mini recommended — M1/M2/M4 with 16+ GB RAM)
- Your primary laptop/phone (for creating accounts beforehand)
- A piece of paper and pen (for writing down credentials — seriously, paper)

---

## Before You Touch the Dedicated Mac

Create all accounts on your primary machine first. The dedicated Mac should never see your personal accounts.

### Task A — Create a Dedicated Email

1. Create a new Gmail or ProtonMail account (e.g., `yourname.openclaw@gmail.com`)
2. This email is ONLY for: API signups, the Apple ID, and bot-related services
3. Write the email and password on paper

### Task B — Create an Anthropic API Account

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up with the NEW email from Task A
3. Add a payment method under **Settings > Billing**
4. **Set spending limits** (critical!):
   - Monthly spend limit: **$30** (you can increase later)
   - Alert threshold: **$15**
5. Go to **Settings > API Keys > Create Key**
   - Name it: `openclaw-dedicated`
   - Copy the key (`sk-ant-...`) and write it on paper — you won't see it again

### Task C — Create a Dedicated Apple ID

1. Go to [appleid.apple.com/account](https://appleid.apple.com/account)
2. Use the new email from Task A
3. Write the password on paper

### Task D — Create a Telegram Bot

1. Open Telegram on your phone
2. Search for **@BotFather**
3. Send `/newbot`
4. Choose a name and username (must end in "Bot")
5. BotFather gives you a **token** — write it on paper (every character matters)
6. Lock it down:
   - `/setjoingroups` > select your bot > **Disable**
   - `/setprivacy` > select your bot > **Enable**

### Task E — Find Your Telegram User ID

You need this to restrict the bot to only respond to you:

1. Search for **@userinfobot** on Telegram
2. Send it any message
3. It replies with your user ID (a number like `123456789`)
4. Write this on paper

---

## Phase 1: Prepare the Mac

### Step 1 — Fresh Install (Recommended)

For a dedicated AI machine, start clean:

1. Erase the disk via Recovery Mode (**Cmd + R** on Intel, hold power button on Apple Silicon)
2. Reinstall macOS
3. Create a single admin account (username: `admin`)

> **Minimum macOS version:** macOS 14 (Sonoma) or later for best compatibility. macOS 12-13 works but may miss security patches.

### Step 2 — Create a Standard User Account

**Why a standard (non-admin) account?** It limits what a compromised agent could do — no system-level changes, no software installation, no security setting modifications.

1. Log in as `admin`
2. System Settings > Users & Groups > **+** button
3. Create a **Standard** account:
   - Name: `openclaw`
   - Password: strong, different from admin
4. From now on, you work as `openclaw`. The admin account is only for system updates.

> **Do NOT use a Guest account** — Guest accounts reset on logout and delete all data.

### Step 3 — Security Hardening

See **[SECURITY.md](SECURITY.md)** for the complete hardening guide. At minimum:

- [ ] Enable Firewall (block all incoming, stealth mode)
- [ ] Enable FileVault (disk encryption)
- [ ] Disable all Sharing services
- [ ] Set up network isolation (guest WiFi)
- [ ] Configure energy settings (never sleep, auto-restart after power failure)
- [ ] Enable auto-login for the openclaw account

---

## Phase 2: Install Software

Log in as `openclaw`. Open Terminal.

### Step 4 — Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

It will ask for the **admin** password. Follow the "Next steps" it prints:

```bash
# Apple Silicon (M1/M2/M4):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Mac:
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Verify: `brew --version`

### Step 5 — Install Node.js

```bash
brew install node
node --version   # Should show v22+
```

### Step 6 — Install Tailscale

```bash
brew install --cask tailscale
```

1. Open Tailscale from Spotlight (Cmd + Space > "Tailscale")
2. Log in (use the dedicated email from Task A)
3. Install Tailscale on your primary laptop too — same account
4. Verify: `ping <mac-tailscale-ip>` from your laptop

### Step 7 — Install Ollama

```bash
brew install ollama
ollama serve &
```

**Choose models based on your RAM:**

| RAM | Recommended Models |
|-----|--------------------|
| 16 GB | `ollama pull qwen2.5:3b` + `ollama pull mistral:7b` |
| 24 GB | Above + `ollama pull mistral-small:latest` (Q4_K_M, ~16 GB VRAM) |
| 32 GB | Above + `ollama pull qwen2.5-coder:14b` |
| 64 GB | Above + `ollama pull qwen2.5:32b` + `ollama pull qwen2.5:72b` |

> **Model quality tip:** For 24 GB machines, `mistral-small:latest` (Q4_K_M quantization) is significantly better than the older `mistral-small:22b` (Q4_0). It uses ~16 GB VRAM with a 16K context window — leaving ~8 GB free for OpenClaw and other services.

> **Heartbeat:** The recommended setup uses the **shell-based heartbeat** (LaunchAgent) — no LLM needed for heartbeats. See [COST-OPTIMIZATION.md](COST-OPTIMIZATION.md) for details.

Pull your primary local model:
```bash
ollama pull mistral-small:latest
```

Test it:
```bash
ollama run mistral-small:latest "Say hello"
# Ctrl+D to exit
```

### Step 8 — Install OpenClaw

```bash
npm install -g openclaw@latest
openclaw --version
```

### Step 9 — Run the Setup Wizard

```bash
openclaw onboard --install-daemon
```

The wizard walks you through:
- **AI provider:** Select Anthropic
- **API key:** Paste the key from your paper
- **Messaging channel:** Select Telegram
- **Bot token:** Paste the full token from your paper
- **Skills:** Skip for now (install them later after reviewing each one)
- **Hooks:** No
- **Additional API keys:** No to all for now
- **Pairing automation:** No
- **Hatch in TUI:** Yes — give your bot a name and personality

The `--install-daemon` flag auto-starts OpenClaw on boot.

### Step 10 — Configure Model Routing

Edit the config:
```bash
nano ~/.openclaw/openclaw.json
```

Set heartbeat to `none` (recommended — use shell LaunchAgent instead of LLM):
```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "target": "none"
      }
    }
  }
}
```

Then install the shell heartbeat LaunchAgent:
```bash
# Copy first, then substitute — never modify the repo file
cp launchagents/com.openclaw.heartbeat.plist ~/Library/LaunchAgents/
sed -i '' "s|YOUR_USER|$(whoami)|g" ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
# Edit credentials: replace YOUR_TELEGRAM_BOT_TOKEN and YOUR_TELEGRAM_CHAT_ID
nano ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
launchctl load ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
```

See **[COST-OPTIMIZATION.md](COST-OPTIMIZATION.md)** for the full model routing guide and heartbeat architecture.

---

## Phase 3: Verify

### Step 11 — First Contact

1. Open Telegram on your phone
2. Find your bot by username
3. Send: `Hello, can you hear me?`

If you get a response — it's alive!

### Step 12 — Safety Checks

Send these test messages and verify:

| Message | Expected Response |
|---------|-------------------|
| `What model are you using?` | Should say Claude Sonnet (not Opus!) |
| `/status` | Shows model, session info |
| `/usage full` | Enables cost tracking |
| `List files in your workspace` | Only ~/.openclaw files |
| `Delete a random file` | Asks for confirmation or refuses |
| `Run: sudo ls /` | Refuses |

### Step 13 — Run the Health Check

```bash
./scripts/health-check.sh
```

Fix anything it flags before relying on the bot for real work.

---

## Phase 4: Go Headless

Before disconnecting peripherals, verify everything works remotely:

**Pre-flight checklist (do all 4 before unplugging):**

1. **Health check:** `./scripts/health-check.sh` — all green?
2. **Telegram test:** Send `/status` to your bot — does it respond?
3. **SSH test:** From your laptop: `ssh openclaw@<tailscale-ip>` — can you connect?
4. **Reboot test:** Restart the Mac (`sudo reboot`), wait 2 minutes, then re-test Telegram and SSH

If all 4 checks pass, you're ready to go headless:

1. Unplug the monitor, keyboard, and mouse
2. Tuck the Mac in a corner — it just needs power and network
3. Chat via Telegram from anywhere
4. Manage via SSH over Tailscale: `ssh openclaw@<tailscale-ip>`

> **Tip:** Keep the Mac plugged into ethernet if possible. Wi-Fi works, but ethernet is more reliable for a 24/7 server.

---

## Your Paper Should Now Have

```
Dedicated Email: ___________________
Dedicated Email Password: ___________________
Anthropic API Key: sk-ant-_________________________
Monthly Limit: $__
Apple ID: ___________________
Apple ID Password: ___________________
Telegram Bot Name: ___________________
Telegram Bot Username: @___________________
Telegram Bot Token: ___________________
Telegram User ID: ___________________
Mac admin password: ___________________
Mac openclaw password: ___________________
FileVault Recovery Key: ___________________
Tailscale Account: ___________________
```

**Store this paper in a safe place. Not on any computer. Not in any cloud.**

---

## Weekly Maintenance (5 minutes)

1. Check API spending at [console.anthropic.com](https://console.anthropic.com)
2. Send `/status` on Telegram — check session size
3. If session is large: `/session new`
4. SSH in and update: `npm update -g openclaw@latest`
5. Log in as admin once a month for macOS updates
