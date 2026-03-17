# LaunchAgents — Why Not OpenClaw Crons?

## The Problem

OpenClaw has a built-in cron system. It works fine for cloud-based tasks (Claude API calls), but **breaks catastrophically with local Ollama models**.

Here's what happens:
1. OpenClaw cron fires, calls a local model (e.g., qwen2.5:14b)
2. Local model is slow or unresponsive -> timeout after N seconds
3. Timeout creates a dead session (`.jsonl` file)
4. Next cron tick: OpenClaw tries again -> another dead session
5. After a few hours: dozens of dead sessions, system unresponsive

This is the **#1 operational issue** with OpenClaw in production.

## The Solution

Use **macOS LaunchAgents** with plain shell scripts for all system maintenance tasks. LaunchAgents are:
- OS-level (don't depend on OpenClaw running)
- Lightweight (shell scripts, no LLM involved)
- Reliable (managed by launchd, auto-restart)

Reserve OpenClaw crons **only** for tasks that genuinely need Claude (cloud).

## Installation

Copy the `.plist` files to your LaunchAgents directory:

> **Note:** The `.plist` files use `/Users/YOUR_USER/` as a placeholder.
> Always copy first, then substitute — never modify the repo files directly:

```bash
cp launchagents/*.plist ~/Library/LaunchAgents/
# Replace YOUR_USER with your actual macOS username in the copies:
sed -i '' "s|YOUR_USER|$(whoami)|g" ~/Library/LaunchAgents/com.openclaw.*.plist

# Load them:
for plist in ~/Library/LaunchAgents/com.openclaw.*.plist; do
    launchctl load "$plist" && echo "Loaded: $plist"
done

# Verify:
launchctl list | grep openclaw
```

## Included LaunchAgents

### com.openclaw.session-cleanup.plist
- **Schedule:** Every 30 minutes
- **Action:** Deletes session files older than 2 hours
- **Why:** Prevents dead session accumulation from timeouts

### com.openclaw.health-check.plist
- **Schedule:** Daily at 06:30
- **Action:** Runs health-check.sh, logs results
- **Why:** Catches issues before they become critical

### com.openclaw.caffeinate.plist
- **Schedule:** Always running
- **Action:** Prevents the Mac from sleeping
- **Why:** The machine needs to be available 24/7

### com.openclaw.safari-cleanup.plist
- **Schedule:** Daily at 22:15
- **Action:** Quits Safari and kills all WebKit processes
- **Why:** Safari tabs accumulate as separate processes overnight. On a 24 GB machine with Ollama running, 10+ open tabs = 2–4 GB RAM. This reclaims it before overnight tasks run.
- **Lesson learned:** This single script eliminated our nightly RAM warnings.

### com.openclaw.heartbeat.plist
- **Schedule:** Hourly, 07:00–21:00 CET
- **Action:** Checks disk usage and Ollama availability, sends Telegram alert on failure
- **Requires:** Edit the plist and replace `YOUR_TELEGRAM_BOT_TOKEN` and `YOUR_TELEGRAM_CHAT_ID` before loading:
  ```bash
  nano ~/Library/LaunchAgents/com.openclaw.heartbeat.plist
  # Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in the EnvironmentVariables block
  ```
- **Why:** Notifies you immediately if disk fills up or Ollama crashes — without any LLM involved

### com.openclaw.memory-index-sync.plist
- **Schedule:** 6x daily, 07:15–22:00 only
- **Action:** Checks if memory index is dirty, forces re-index if needed
- **Why:** OpenClaw's `sync.watch: true` doesn't reliably detect new files. Without this, memory search returns stale results.
- **Why not hourly 24/7?** Running at night triggers the Ollama embedding model unnecessarily, keeping RAM occupied and preventing full overnight recovery.

## Adding Your Own

Create a `.plist` file following the same pattern. Key fields:
- `Label`: Unique identifier (e.g., `com.openclaw.my-task`)
- `ProgramArguments`: The command to run
- `StartInterval`: Run every N seconds
- `StartCalendarInterval`: Run at specific times
- `RunAtLoad`: Run immediately when loaded
- `StandardOutPath` / `StandardErrorPath`: Log files

**Golden rule:** Shell scripts only. No Ollama. No LLM calls.
