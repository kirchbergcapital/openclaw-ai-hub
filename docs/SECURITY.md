# Security Hardening Guide

Your dedicated Mac will run 24/7 with an AI agent that has shell access. Harden it properly.

---

## 1. Firewall

**Logged in as admin:**

1. System Settings > Network > Firewall > **Turn ON**
2. Click Options:
   - **Block all incoming connections** — start strict, loosen later if needed
   - **Enable stealth mode** — makes the Mac invisible to network scans

```bash
# CLI alternative:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on
```

---

## 2. FileVault (Disk Encryption)

1. System Settings > Privacy & Security > FileVault > **Turn On**
2. Choose "Create a recovery key and do not use my iCloud account"
3. **Write the recovery key on paper** — if you lose this AND the password, the disk is unrecoverable

---

## 3. Disable All Sharing Services

System Settings > General > Sharing — turn OFF everything:

- Screen Sharing — OFF
- File Sharing — OFF
- Remote Login — OFF (you'll use Tailscale SSH instead)
- Remote Management — OFF
- Content Caching — OFF
- AirDrop — OFF (General > AirDrop & Handoff)

---

## 4. Network Isolation (Critical!)

Your AI machine has shell access. If it gets compromised (prompt injection, malicious skill), you do NOT want it reaching your other devices — your NAS, smart home, family computers.

### Option A — Best: Router Guest Network (5 minutes)

Most modern routers support a guest WiFi network. Guest networks are automatically isolated from your main network.

1. Log into your router admin panel
2. Find WiFi > Guest Access
3. Enable the guest network, set a password
4. Connect the Mac to this guest network

The Mac can reach the internet but cannot see or attack your other devices.

### Option B — Good: Separate VLAN

If your router supports VLANs:
1. Create a dedicated VLAN for the AI machine
2. Configure firewall rules: allow outbound internet, block access to other VLANs

### Option C — Minimum: Same Network

If neither option is possible, the macOS firewall plus OpenClaw's tool policies provide some protection. This is the weakest option.

**Strong recommendation: Option A.** It takes 5 minutes and gives you hardware-level isolation.

---

## 5. Standard User Account

Never run OpenClaw as an admin user. A standard account cannot:
- Install system-level software
- Modify system files or security settings
- Access other users' home directories
- Run `sudo` commands (without the admin password)

This limits the blast radius if the agent is compromised.

---

## 6. Energy Settings

The Mac needs to run 24/7:

1. System Settings > Energy Saver (or Displays > Advanced)
2. Turn display off after: **5 minutes** (saves power, doesn't affect OpenClaw)
3. **Prevent automatic sleeping when display is off** — ON
4. **Start up automatically after a power failure** — ON

---

## 7. Auto-Login

1. System Settings > Users & Groups > Login Options
2. Automatic login: **openclaw**

This ensures OpenClaw restarts after power outages.

---

## 8. Tailscale SSH (Instead of macOS Remote Login)

With Tailscale SSH enabled:
- Only devices on your Tailscale network can SSH in
- macOS "Remote Login" stays OFF (nothing exposed to local network)
- Connection is end-to-end encrypted

Enable it at: [login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines) > click your Mac > enable Tailscale SSH

---

## 9. OpenClaw Tool Policies

Configure what the agent can do autonomously vs. what needs approval:

| Action | Policy | Reason |
|--------|--------|--------|
| File read (workspace) | Allow | Agent needs workspace access |
| File write (workspace) | Allow | Memory, notes, drafts |
| File write (outside workspace) | Deny | Prevent system file modification |
| File delete | Deny | No autonomous deletions |
| Shell (read-only: ls, cat, grep) | Allow | Observation is safe |
| Shell (write: mkdir, mv, cp) | Ask | Requires approval |
| Shell (destructive: rm, kill, sudo) | Deny | Always blocked |
| Web search | Allow | Research is safe |
| Web fetch | Allow | Reading pages is safe |
| Browser (full control) | Deny | High risk — enable later if needed |
| Send messages (email, chat) | Deny | Never send on your behalf |
| Cron jobs | Ask | New automations need approval |

---

## 10. SOUL.md Boundaries

Add clear boundaries to your agent's `SOUL.md`:

```markdown
## Boundaries — Hard Rules
- NEVER execute commands that modify system settings
- NEVER install software without asking first
- NEVER access files outside your workspace without asking
- NEVER send emails, messages, or make purchases without explicit approval
- NEVER share personal, business, or financial details
- If unsure whether an action is safe, ASK first
```

---

## 11. API Spending Controls

Without limits, a runaway automation can burn through $50-200 in hours.

1. **Anthropic console:** Set monthly limit and alert threshold
2. **Model routing:** Use Sonnet (not Opus) as primary, local models for heartbeat
3. **Session hygiene:** Start fresh sessions regularly, don't let context grow unbounded

See **[COST-OPTIMIZATION.md](COST-OPTIMIZATION.md)** for details.

---

## Emergency: Kill Switch

**Level 1 — Pause (from Telegram):**
```
/stop
```

**Level 2 — Kill the process (from your laptop via SSH):**
```bash
ssh openclaw@<tailscale-ip>
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Level 3 — Nuclear:**
1. Revoke the API key at console.anthropic.com
2. Revoke the Telegram bot token via @BotFather > `/revoke`
3. Disconnect the Mac from the network

---

## Security Checklist

```
[ ] Firewall enabled (block all incoming + stealth mode)
[ ] FileVault enabled (recovery key stored on paper)
[ ] All sharing services disabled
[ ] Mac on guest WiFi / separate VLAN
[ ] Running as standard (non-admin) user
[ ] Tailscale SSH enabled, macOS Remote Login disabled
[ ] OpenClaw tool policies configured
[ ] SOUL.md boundaries set
[ ] API spending limits configured
[ ] Auto-login and auto-restart configured
[ ] Kill switch procedure documented and tested
```
