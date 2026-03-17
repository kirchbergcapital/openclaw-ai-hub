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

```bash
cp launchagents/*.plist ~/Library/LaunchAgents/

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

## Adding Your Own

Create a `.plist` file following the same pattern. Key fields:
- `Label`: Unique identifier (e.g., `com.openclaw.my-task`)
- `ProgramArguments`: The command to run
- `StartInterval`: Run every N seconds
- `StartCalendarInterval`: Run at specific times
- `RunAtLoad`: Run immediately when loaded
- `StandardOutPath` / `StandardErrorPath`: Log files

**Golden rule:** Shell scripts only. No Ollama. No LLM calls.
