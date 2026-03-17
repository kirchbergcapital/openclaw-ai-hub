# Troubleshooting

## Bot Doesn't Respond on Telegram

1. **Check if the gateway is running:**
   ```bash
   openclaw status
   ```
   If not running:
   ```bash
   launchctl kickstart -k gui/$UID/ai.openclaw.gateway
   ```

2. **Check the logs:**
   ```bash
   tail -50 ~/.openclaw/logs/gateway.err.log
   ```

3. **Verify Tailscale is connected** (if accessing remotely):
   ```bash
   tailscale status
   ```

4. **Verify the Telegram bot token** — if you changed it, update `~/.openclaw/openclaw.json` and restart the gateway.

---

## Ollama Model Won't Load

**Symptom:** "model not found" or extremely slow responses.

1. **Check available models:**
   ```bash
   ollama list
   ```

2. **Check available RAM:**
   ```bash
   # macOS
   sysctl hw.memsize | awk '{print $2/1073741824 " GB"}'
   # Check what's using RAM
   top -l 1 | head -10
   ```

3. **Model too large for your RAM?** Use a smaller variant:
   - 16 GB RAM → max 7B models
   - 24 GB RAM → max 14B models
   - 64 GB RAM → up to 32B models

4. **Ollama not using GPU?** On Apple Silicon, check the MLX symlink:
   ```bash
   ls "$(dirname $(which ollama))/libmlxc.dylib" || echo "Symlink missing!"
   # Fix:
   ln -sf /opt/homebrew/lib/libmlxc.dylib "$(dirname $(which ollama))/libmlxc.dylib"
   brew services restart ollama
   ```

---

## Claude API Errors

**"Invalid API key":**
- Check the key: `echo $ANTHROPIC_API_KEY | cut -c1-20`
- Should start with `sk-ant-api03-` (not `sk-ant-sk-ant-` — double prefix is a common bug)
- Fix double prefix in `.env`:
  ```bash
  sed -i '' "s|ANTHROPIC_API_KEY=sk-ant-sk-ant-|ANTHROPIC_API_KEY=sk-ant-|" ~/.openclaw/.env
  ```

**"Rate limit exceeded":**
- You're sending too many requests. Wait a few minutes.
- Consider using local models for sub-tasks to reduce API calls.

**"Insufficient funds":**
- Add credits at [console.anthropic.com](https://console.anthropic.com)
- Check your spending limit — it may be too low.

---

## Gateway Won't Start / Crash Loop

1. **Check the error log:**
   ```bash
   tail -100 ~/.openclaw/logs/gateway.err.log
   ```

2. **Common cause — plugin ID mismatch after update:**
   ```bash
   openclaw doctor
   ```
   Follow its recommendations.

3. **Port conflict** (something else is using the gateway port):
   ```bash
   lsof -i :18789
   ```
   Kill the conflicting process or change the port in `openclaw.json`.

4. **Hard restart:**
   ```bash
   launchctl bootout gui/$UID ~/Library/LaunchAgents/ai.openclaw.gateway.plist
   launchctl bootstrap gui/$UID ~/Library/LaunchAgents/ai.openclaw.gateway.plist
   ```

---

## Slow Responses

1. **Check which model is being used** — send `/status` on Telegram
   - If it's using Opus instead of Sonnet, fix your model config
   - If it's using a local 14B+ model, responses will be slower

2. **Session too large** — check context usage via `/status`
   - If context is >50% full, start a fresh session: `/session new`

3. **Ollama models competing for RAM:**
   ```bash
   # Unload heavy models you're not using
   ollama stop mistral-small:22b
   ollama stop qwen2.5:32b
   ```

4. **Chrome renderer accumulation** (if browser is enabled):
   ```bash
   # Kill old Chrome/WebKit processes
   pkill -f "Chrome Helper (Renderer)"
   pkill -f "WebKit.WebContent"
   ```

---

## RAM Issues

**Symptom:** Mac becomes sluggish, swap usage high.

1. **Check memory pressure:**
   ```bash
   memory_pressure
   ```

2. **Unload heavy Ollama models:**
   ```bash
   ollama stop qwen2.5:14b
   ollama stop mistral-small:22b
   ```

3. **Kill accumulated browser processes:**
   ```bash
   pkill -f "Chrome Helper (Renderer)"
   pkill -f "WebKit.WebContent"
   pkill -f "Safari"
   ```

4. **Consider setting Ollama's KEEP_ALIVE:**
   - `-1` = keep models loaded permanently (fast, uses more RAM)
   - `5m` = unload models after 5 minutes of inactivity (saves RAM, slower first response)

---

## Vector Memory Index Out of Sync

**Symptom:** Memory search returns stale or incomplete results.

OpenClaw's `sync.watch: true` config is unreliable — files may not get indexed automatically.

**Fix — Force reindex:**
```bash
openclaw memory index --force
openclaw memory status
# Should show: Indexed: N/N files · Dirty: no
```

**Permanent fix:** Set up a LaunchAgent to periodically reindex. See [launchagents/README.md](../launchagents/README.md).

---

## Session Cleanup

Dead sessions (from timeouts, crashes) accumulate over time.

**Manual cleanup:**
```bash
# Find sessions older than 2 hours
find ~/.openclaw/agents/main/sessions -name "*.jsonl" -mmin +120 -type f

# Delete them (careful!)
find ~/.openclaw/agents/main/sessions -name "*.jsonl" -mmin +120 -type f -delete
```

**Automated:** Use the session-cleanup LaunchAgent or `scripts/session-cleanup.sh`.

---

## Update Problems

**After updating OpenClaw:**
1. Run `openclaw doctor` to check for issues
2. Restart the gateway:
   ```bash
   launchctl kickstart -k gui/$UID/ai.openclaw.gateway
   ```

**After updating Ollama:**
1. Re-create the MLX symlink (Apple Silicon):
   ```bash
   ln -sf /opt/homebrew/lib/libmlxc.dylib "$(dirname $(which ollama))/libmlxc.dylib"
   ```
2. Restart Ollama:
   ```bash
   brew services restart ollama
   ```
