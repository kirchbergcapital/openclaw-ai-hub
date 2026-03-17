# Heartbeat

Keep this file simple. Binary logic only.

**Model: mistral-small:22b** (FIXED — warm, already in RAM, no extra load)
**Config: lightContext: true** (reduces context, prevents hangs)

> Note: qwen2.5:3b was previously used but caused repeated timeout issues.
> Do NOT switch back to qwen2.5:3b for heartbeat without explicit testing.

## Checks

1. Is disk usage below 90%? → `df -h / | awk 'NR==2{print $5}'`
2. Is Ollama running? → `pgrep -x ollama > /dev/null && echo OK`

## Response

- If both checks pass: respond with `HEARTBEAT_OK`
- If any check fails: send a 1–3 sentence alert via Telegram describing which check failed

Do NOT:
- Generate summaries or reports
- Analyze trends
- Read or process memory files
- Perform any task beyond the two checks above
