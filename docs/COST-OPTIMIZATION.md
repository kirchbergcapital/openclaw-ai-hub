# Cost Optimization Guide

Without these settings, a single runaway automation can burn through $50-200 in hours. This is the #1 thing people regret not setting up.

## Model Routing — The Biggest Lever

**Don't use Opus for everything.** Claude Opus is 5-10x more expensive than Sonnet, and for most tasks, Sonnet is more than capable.

### Recommended Model Chain

| Role | Model | Cost | Use Case |
|------|-------|------|----------|
| Primary | Claude Sonnet | ~$3-15/M tokens | Your conversations |
| Heartbeat | Small local model (see below) | Free | Periodic health checks |
| Sub-agent | Mid-size local model | Free | Drafts, summaries, translations |
| Code | Local coder model | Free | Code generation tasks |

### Choosing Your Heartbeat Model

**Rule:** Use the model that's already warm (loaded in RAM).

If your primary local model runs constantly anyway (e.g. for sub-agents), use it for heartbeats too — no extra RAM cost. Using a *separate* tiny model just for heartbeats only makes sense if your primary model frequently unloads.

**Minimum hardware for local models:**
- 16 GB RAM → 7B models (heartbeat + basic sub-agents)
- 24 GB RAM → 14B models (good quality sub-agents + primary local)
- 48+ GB RAM → 22B+ models (near-Claude quality local inference)

### Configuration

In `~/.openclaw/openclaw.json`:
```json
{
  "models": {
    "primary": "anthropic/claude-sonnet-4-6"
  },
  "agents": {
    "defaults": {
      "heartbeat": {
        "model": "ollama/YOUR_WARM_MODEL"
      }
    }
  }
}
```

Or tell your bot directly via Telegram:
```
Switch to Claude Sonnet as the default model.
Use the local Ollama qwen2.5:3b for heartbeat checks.
```

---

## Heartbeat Architecture

> **TL;DR:** Don't use a local LLM for heartbeats. Use a shell script LaunchAgent instead. LLM heartbeats cause the exact problem they're supposed to detect.

### The Problem with LLM Heartbeats

The OpenClaw built-in heartbeat calls a local LLM (mistral, qwen, etc.) to check system health. In production, this causes a critical failure mode:

1. Ollama is slow/cold (just restarted, model not warm)
2. Heartbeat calls LLM → hangs for 10 minutes (embedded run timeout)
3. This **blocks the main session lane** — you can't talk to the assistant
4. You have to SSH in and restart the gateway manually

The heartbeat is trying to detect system problems, but it creates the very problem you want to detect.

### Solution: Shell LaunchAgent (Recommended)

Replace the LLM heartbeat with a pure shell script. No model, no context, no hang possible.

**Setup:**

```bash
# 1. Copy the script
cp scripts/heartbeat-check.sh ~/.openclaw/workspace/scripts/heartbeat-check.sh
chmod +x ~/.openclaw/workspace/scripts/heartbeat-check.sh

# 2. Edit the script — add your Telegram bot token and chat ID
nano ~/.openclaw/workspace/scripts/heartbeat-check.sh

# 3. Install the LaunchAgent
cp launchagents/com.openclaw.heartbeat.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.openclaw.heartbeat.plist

# 4. Disable the OpenClaw heartbeat
# In openclaw.json, set target to "none":
```

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

**Test:**
```bash
bash ~/.openclaw/workspace/scripts/heartbeat-check.sh
echo "Exit: $?"  # 0 = OK, 1 = Alert sent
```

The script checks:
- Disk usage > 90% → Telegram alert
- Ollama not reachable → Telegram alert
- Everything OK → silent exit 0

**Runs:** Every hour, 07:00–21:00 CET (UTC 06:00–20:00). Adjust the plist for your timezone.

### If You Still Want an LLM Heartbeat

For non-system-check heartbeats (e.g. "remind me of todos", "check for urgent emails"), an LLM heartbeat is fine — but keep it simple:

- Use `lightContext: true` to reduce token load
- Keep HEARTBEAT.md to **binary logic only** — 2 checks, OK or Alert
- Use `mistral-small:22b` (stays warm in RAM) not a tiny model that cold-loads

**HEARTBEAT.md — good:**
```markdown
1. Shell: df -h / | awk 'NR==2{print $5}'  → alert if > 90%
2. Shell: pgrep -x ollama                    → alert if not running
→ OK: HEARTBEAT_OK
→ Alert: send 1 sentence via message tool
```

**HEARTBEAT.md — bad:**
```markdown
1. Check gateway, ollama, tailscale, docker, 5 other services
2. Analyze memory usage trends
3. Review recent conversation quality
```

---

## Session Hygiene

Long sessions accumulate context, which means more tokens per message. A session at 80% context capacity costs roughly 4x more per message than a fresh session.

### Rules of Thumb

1. **Start a fresh session for each new topic:** `/session new`
2. **Check session size periodically:** `/status`
3. **When context is >50% full, start fresh**
4. **Don't let the agent keep "remembering" everything** — that's what MEMORY.md is for

### Enable Usage Tracking

Send this to your bot:
```
/usage full
```

Every reply now shows token count and estimated cost. This awareness alone reduces spending.

---

## Avoid Runaway Automations

### The #1 Trap: OpenClaw Crons with Local Models

**Never set up OpenClaw cron jobs that call local Ollama models.**

What happens:
1. Cron fires, calls local model (e.g., qwen2.5:14b)
2. Model is slow or hangs → timeout after N seconds
3. Timeout creates a dead session
4. Next cron tick: new dead session
5. After hours: dozens of dead sessions, system unresponsive

**Solution:** Use macOS LaunchAgents with shell scripts for system tasks. See [launchagents/README.md](../launchagents/README.md).

OpenClaw crons are fine **only** when they use Claude (cloud) — cloud calls don't hang the same way.

### API Spending Limits

Set these at [console.anthropic.com](https://console.anthropic.com):

1. **Monthly limit:** Start at $30, increase as needed
2. **Alert threshold:** Set at 50% of your limit

---

## Monthly Cost Expectations

| Usage Level | Description | Estimated Monthly Cost |
|-------------|-------------|----------------------|
| Light | 5-10 messages/day, no automations | $5-15 |
| Moderate | 20 messages/day, basic heartbeat | $15-40 |
| Heavy | 50+ messages/day, multiple sub-agents, browser | $40-100+ |

**The biggest cost drivers:**
1. Using Opus instead of Sonnet (5-10x more expensive)
2. Bloated sessions (context window fills up → more tokens per message)
3. Runaway cron jobs / heartbeats
4. Browser automation (generates lots of tokens from page content)

---

## Quick Wins Checklist

```
[ ] Primary model set to Sonnet (not Opus)
[ ] Heartbeat using local model (qwen2.5:3b)
[ ] Heartbeat interval: 60 minutes, schedule: 8-22
[ ] HEARTBEAT.md: binary logic, 2-3 checks max
[ ] Usage tracking enabled (/usage full)
[ ] API spending limit set ($30/month to start)
[ ] Alert threshold set (50% of limit)
[ ] Session cleanup routine (manual or LaunchAgent)
[ ] No OpenClaw crons calling local models
```
