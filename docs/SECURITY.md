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

## 12. Endpoint Protection (Antivirus)

Your AI machine runs 24/7 with shell access. It downloads files, executes code, installs packages, and interacts with the internet autonomously. This is a fundamentally different threat profile than a laptop that sits idle most of the day.

### Why macOS Built-In Security Is Not Enough

macOS ships with Gatekeeper (app notarization) and XProtect (basic malware signatures). These provide a baseline, but they are designed for interactive desktop use — not for a machine running autonomous agents that pull code from the internet, execute arbitrary shell commands, and process untrusted input around the clock.

A dedicated endpoint protection suite adds:

- **Real-time file scanning** — catches malicious payloads before they execute
- **Web and network filtering** — blocks known malicious domains and C2 callbacks
- **Behavioral detection** — flags suspicious process chains (e.g., a Python script spawning curl to an unknown IP)
- **Scheduled deep scans** — catches dormant threats that slipped past real-time protection

### Recommended Products

| Product | Real-Time Protection | Cost | Notes |
|---|---|---|---|
| ESET Cyber Security / ESET HOME Security | Yes | Paid | Full endpoint suite for macOS, includes firewall and web filtering |
| Sophos Home | Yes | Free tier available | Centralized dashboard, good for managing multiple machines |
| Malwarebytes | Yes (Premium) | Free tier available | Strong on-demand scanning, premium adds real-time protection |
| ClamAV | No | Free, open-source | Signature-based scanning only, no real-time protection — suitable as a supplementary scanner but not as a primary defense |

Choose one product with real-time protection as your primary defense. ClamAV can serve as a secondary on-demand scanner.

### Installation Strategy

Install the endpoint protection software on **both** the admin account and the service account:

- **Admin account** — manages the security software, receives alerts, handles configuration and updates
- **Service account** (where OpenClaw runs) — is actively protected by the software's real-time scanning and behavioral detection

This separation ensures the agent cannot modify or disable its own security configuration while still being fully covered by it.

### Scheduled Scans

Configure a daily full-system scan during idle hours. A good default:

```
Schedule: Daily at 05:00
Scope:    Full system scan
Action:   Quarantine detected threats, notify admin account
```

Most endpoint protection suites let you configure this through their GUI or a plist/launchd job. Run the scan when the machine is idle (no heavy agent workloads) to avoid performance impact.

### What to Monitor

Review your endpoint protection dashboard periodically for:

- Quarantined files (inspect what was caught and why)
- Blocked network connections (may indicate a compromised dependency)
- Scan failures (ensure scans are actually completing)

---

## 13. GitHub Repository Security

If you host your OpenClaw configuration, scripts, automations, or custom tools on GitHub, you should enable the platform's built-in security features. All four features below are **free** for public repositories and free for private repositories on GitHub Free/Pro/Team plans.

### Features to Enable

#### Secret Scanning

Detects API keys, tokens, credentials, and other secrets that have been committed to your repository. GitHub scans the full commit history, not just the latest push.

This is especially important for AI setups: your agent may generate code, commit configs, or push files that accidentally contain tokens from environment variables or API responses.

#### Push Protection

**Blocks pushes** that contain detected secrets before they reach the remote repository. This is your last line of defense — if a secret makes it into a commit, Push Protection prevents it from ever becoming public.

Without Push Protection, a leaked secret is in your Git history forever (even if you delete the file in a later commit). Cleaning it requires a force-push and history rewrite.

#### Dependabot Alerts

Monitors your dependencies (package.json, requirements.txt, Gemfile, etc.) for known vulnerabilities from the GitHub Advisory Database. You receive alerts when a vulnerable version is detected.

#### Dependabot Security Updates

Automatically creates pull requests to update vulnerable dependencies to the minimum safe version. Review and merge these PRs promptly.

### How to Enable

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Code security and analysis** (or **Code security** on newer UIs)
3. Enable all four features:
   - Secret scanning: **Enable**
   - Push protection: **Enable**
   - Dependabot alerts: **Enable**
   - Dependabot security updates: **Enable**

For **organizations**: enable these at the organization level under **Settings** > **Code security and analysis** > **Enable all**. New repositories will automatically inherit these settings.

### Pre-Commit Hook for Local Secret Scanning

Push Protection catches secrets at the remote, but you can catch them earlier with a local pre-commit hook. This prevents secrets from entering your Git history in the first place.

Using [pre-commit](https://pre-commit.com/) with a secret scanner:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0  # check for latest version
    hooks:
      - id: gitleaks
```

Install and activate:

```bash
pip install pre-commit
pre-commit install
```

Every commit will now be scanned locally before it is created. If a secret is detected, the commit is blocked and you can remove the secret before it enters history.

### Why This Matters for AI Setups

Autonomous agents interact with APIs, process credentials in environment variables, and may generate or modify code that contains sensitive values. The risk of accidental secret exposure is significantly higher than in a traditional development workflow. Layering GitHub's server-side scanning with local pre-commit hooks provides defense in depth.

---

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

Add the following items to your security checklist:

```
[ ] Endpoint protection installed (admin + service account)
[ ] Real-time protection enabled and verified
[ ] Daily scheduled scan configured (e.g., 05:00)
[ ] Endpoint protection dashboard reviewed (no unresolved alerts)
[ ] GitHub Secret Scanning enabled
[ ] GitHub Push Protection enabled
[ ] Dependabot Alerts enabled
[ ] Dependabot Security Updates enabled
[ ] Pre-commit hooks for secret scanning installed and active
```
