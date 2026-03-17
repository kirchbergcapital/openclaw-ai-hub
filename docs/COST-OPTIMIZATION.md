# Cost Optimization Guide

Without these settings, a single runaway automation can burn through $50-200 in hours. This is the #1 thing people regret not setting up.

## Model Routing — The Biggest Lever

**Don't use Opus for everything.** Claude Opus is 5-10x more expensive than Sonnet, and for most tasks, Sonnet is more than capable.

### Recommended Model Chain

| Role | Model | Cost | Use Case |
|------|-------|------|----------|
| Primary | Claude Sonnet | ~$3-15/M tokens | Your conversations |
| Heartbeat | ollama/qwen2.5:3b | Free | Periodic health checks |
| Sub-agent | ollama/mistral:7b | Free | Drafts, summaries, translations |
| Code | ollama/qwen2.5-coder:14b | Free | Code generation tasks |

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
        "model": "ollama/qwen2.5:3b"
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

## Heartbeat Tuning

Heartbeats are periodic checks where the agent "wakes up" and reviews its state. Each heartbeat costs tokens.

### Reduce Heartbeat Frequency

Default is often every 30 minutes. For most users, every 60 minutes is fine:

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "interval": 3600,
        "schedule": "8-22",
        "model": "ollama/qwen2.5:3b"
      }
    }
  }
}
```

- `interval: 3600` — Check every 60 minutes instead of 30
- `schedule: "8-22"` — Only between 8am and 10pm (no overnight checks)

**Savings:** ~50% on heartbeat costs vs. default settings.

### Keep HEARTBEAT.md Simple

Your HEARTBEAT.md should have **binary logic** — 2-3 simple checks that return OK or Alert. Nothing more.

**Good:**
```markdown
1. Check: Is the gateway process running?
2. Check: Is disk usage below 90%?
→ If both OK: respond "HEARTBEAT_OK"
→ If any fail: alert via Telegram
```

**Bad:**
```markdown
1. Check gateway, ollama, tailscale, docker, 5 other services
2. Analyze memory usage trends
3. Review recent conversation quality
4. Generate a daily summary
```

Complex heartbeats with 8+ rules cause small models (3b) to produce verbose, unpredictable output instead of a clean OK/Alert.

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
