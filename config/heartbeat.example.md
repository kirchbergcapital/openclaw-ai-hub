# Heartbeat

Keep this file simple. Binary logic only — the heartbeat model (qwen2.5:3b) cannot handle complex rule sets.

## Checks

1. Is the gateway process responsive?
2. Is disk usage below 90%?

## Response

- If both checks pass: respond with `HEARTBEAT_OK`
- If any check fails: send an alert message via Telegram describing which check failed

Do NOT:
- Generate summaries or reports
- Analyze trends
- Read or process memory files
- Perform any task beyond the two checks above
