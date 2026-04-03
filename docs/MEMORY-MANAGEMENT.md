# Memory Management Best Practices

> A practical guide to giving your AI assistants persistent, structured memory across sessions and nodes.

---

## Why Memory Matters

AI assistants have no memory between sessions. Every new conversation starts from zero. Without structured memory, you will find yourself:

- Re-explaining your infrastructure, conventions, and preferences every single time
- Getting inconsistent answers because the assistant lacks context it had yesterday
- Losing decisions, rules, and lessons learned from past sessions
- Wasting 10-15 minutes per session just on context-setting

For single-node setups, this is annoying. For multi-node setups (2+ machines running AI agents), it becomes a serious operational problem: nodes make contradictory decisions, duplicate work, or violate rules that only one node learned about.

Structured memory solves all of this. Think of it as giving your AI assistant a notebook it can read at the start of every conversation.

---

## Memory Architecture

### Single Node

The simplest setup uses a flat file structure that your AI assistant reads at session start.

**Core components:**

- **`MEMORY.md`** -- The central index file. Contains a table of contents pointing to individual memory files. This is the file your assistant loads first.
- **`memory/`** -- A folder of individual memory files, organized by topic. Each file covers one subject (a project, a system, a set of rules).
- **`archives/`** -- Where completed or stale memory files go to retire. Still accessible if needed, but not loaded by default.

**Character limit management:**

Keep your active `MEMORY.md` index under ~18,000 characters. Beyond this threshold, assistants start losing detail from the beginning of the context. When you approach the limit:

1. Identify memory files that are stale or no longer actively referenced
2. Move them to `archives/`
3. Remove their entries from `MEMORY.md`
4. If you need the archived content later, you can always reference it explicitly

```
~/.claude/
├── MEMORY.md              # Index file (~18k char max)
├── memory/
│   ├── system_servers.md
│   ├── project_webapp.md
│   ├── feedback_deploy.md
│   └── reference_apis.md
└── archives/
    ├── project_old_migration.md
    └── system_legacy_db.md
```

### Multi-Node (2+ Machines)

When you run AI agents on multiple machines, each node accumulates its own memories. Without synchronization, nodes drift apart -- one learns a lesson, the others keep making the same mistake.

**The solution: hub-and-spoke architecture via a private Git repository.**

Each node maintains its own memory folder, and a shared folder holds cross-node knowledge. A sync script commits and pushes changes, and pulls updates from other nodes.

### Recommended Folder Structure (Multi-Node)

```
memory-hub/
├── node-1/                    # First node's memories
│   ├── MEMORY.md              # Node 1's local index
│   └── memory/
│       ├── system_local.md
│       └── project_alpha.md
├── node-2/                    # Second node's memories
│   ├── MEMORY.md              # Node 2's local index
│   └── memory/
│       ├── system_local.md
│       └── project_beta.md
├── shared/                    # Cross-node knowledge
│   ├── infrastructure.md      # Network topology, shared services
│   ├── conventions.md         # Naming standards, coding rules
│   └── decisions.md           # Architecture decisions that affect all nodes
└── sync-log.md                # Audit trail of sync events
```

**Key rules:**
- Each node only writes to its own folder and to `shared/`
- Nodes pull the full repo at session start to get updates from other nodes
- One node is designated as the authority for `shared/` to prevent merge conflicts
- The `sync-log.md` provides an audit trail so you can trace when knowledge was propagated

---

## Memory Types (Taxonomy)

Consistent categorization makes memory files findable and manageable. Use these five types as a starting taxonomy and adapt as needed.

### System / Infrastructure

Hardware specs, installed services, network configuration, port assignments, database locations. Things that change rarely but are referenced constantly.

**Examples:**
```markdown
# Node 1 System Config
- Hardware: Mac Mini M4, 24GB RAM
- PostgreSQL: port 5433 (non-default to avoid conflicts)
- Redis: port 6380
- Services: nginx (443), app-server (3000), background-worker (3001)
```

**Decay rate:** Slow. Update when infrastructure changes. Review monthly.

### Feedback / Corrections

Lessons learned from incidents, mistakes, and user corrections. These are the most valuable memories because they prevent repeated failures.

**Examples:**
```markdown
# NEVER restart the database during business hours
Learned 2025-11-15: Restarting PostgreSQL at 2pm caused 30 minutes
of downtime. Connection pool took 10 minutes to recover.
Rule: Database restarts only between 02:00-05:00 local time.
```

```markdown
# Always check disk space before large imports
Learned 2026-01-08: CSV import filled /tmp and crashed the worker.
Rule: Verify 2x the file size is available in /tmp before importing.
```

**Decay rate:** Very slow. Feedback memories should persist for months or longer. The pain they prevent far outweighs the storage cost.

### Project / Active Work

Ongoing initiatives, their current status, and key context. These change frequently and go stale fast.

**Examples:**
```markdown
# Project: API v2 Migration
Status: In progress (started 2026-03-01)
Branch: feature/api-v2
Current phase: Endpoint conversion (18 of 42 done)
Blocked on: Auth middleware rewrite (waiting on security review)
Next step: Convert /users endpoints after auth is unblocked
```

**Decay rate:** Fast. Review weekly. Archive when the project completes or pauses for 30+ days.

### Reference / Pointers

External system IDs, API endpoints, documentation links, configuration values. Things you look up repeatedly.

**Examples:**
```markdown
# External Service IDs
- Stripe account: acct_1234567890
- AWS region: eu-west-1
- Monitoring dashboard: https://grafana.internal/d/abc123
- CI pipeline: pipeline ID 4872
```

**Decay rate:** Medium. Review monthly. IDs and URLs change when services are migrated or upgraded.

### Shared / Cross-Node

Facts, rules, and conventions that all nodes need to know. Only applicable in multi-node setups. This is the most carefully managed category because inconsistency here causes the worst problems.

**Examples:**
```markdown
# Git Conventions (all nodes)
- Branch naming: {type}/{ticket}-{short-description}
- Commit style: conventional commits (feat:, fix:, chore:)
- Always rebase, never merge, for feature branches
- PR required for main -- no direct pushes
```

**Decay rate:** Slow. These are foundational rules. Review monthly or when conventions change.

---

## Staleness Prevention

**Stale data is the number one memory problem.** A memory file that says "Project X is in progress" when Project X finished two months ago will cause your AI assistant to make wrong assumptions, suggest irrelevant actions, and waste your time.

### Scheduled Reviews

Review your memory files on a fixed schedule. Twice per week is a good starting cadence.

| Memory Type        | Review Frequency | Archive After             |
|--------------------|------------------|---------------------------|
| Feedback           | Monthly          | 6+ months with no relevance |
| System             | Monthly          | When infrastructure changes |
| Project            | Weekly           | On completion or 30 days idle |
| Reference          | Monthly          | When external system changes |
| Shared (cross-node)| Bi-weekly        | When convention is superseded |

### Decay Rules

Apply these rules during each review:

1. **Project files not updated in 14 days:** Add a `[STALE?]` flag. Investigate whether the project is still active.
2. **Project files not updated in 30 days:** Archive unless there is a clear reason to keep them.
3. **Reference files with broken links or changed IDs:** Update immediately or archive.
4. **Feedback files older than 6 months:** Evaluate whether the lesson still applies. Keep if yes, archive if the underlying system has changed.
5. **Any file with factually incorrect information:** Fix or archive immediately. Wrong data is worse than no data.

### Archive Pattern

Moving files to archives is cheap and reversible. Deleting is permanent. Always prefer archiving.

```bash
# Archive a completed project
mv memory/project_api_migration.md archives/project_api_migration.md

# Update MEMORY.md to remove the entry from the active index
# (or move it to an "Archived" section at the bottom)
```

---

## Session Summaries

Decisions made during sessions are the most common thing forgotten. You spend 45 minutes in a session working through an architecture decision, and three days later neither you nor your AI assistant remembers the outcome.

### When to Write a Session Summary

- After any architecture or design decision
- When a new rule or convention is established
- After resolving a significant incident
- When a project reaches a milestone
- After any session where you say "we should remember this"

### Format

Use a consistent structure so summaries are scannable:

```markdown
# Session Summary: 2026-03-15

## Key Decisions
- Chose PostgreSQL over MySQL for the new service (reasons: JSONB support, team familiarity)
- API rate limiting set to 100 req/min per user, 1000 req/min per org

## Changes Made
- Created migration scripts in /db/migrations/
- Updated .env.example with new DB connection string
- Added rate-limit middleware to API gateway

## Open Items
- [ ] Load test the rate limiter under realistic traffic
- [ ] Update API documentation with new rate limit headers
- [ ] Decide on rate limit response format (429 body structure)
```

### Auto-Archive Session Summaries

Session summaries are high-value for the first few weeks, then rapidly lose relevance. Set a 30-day auto-archive rule:

- Summaries older than 30 days get moved to `archives/sessions/`
- Key decisions from those summaries should be extracted into permanent memory files before archiving
- Open items that are still open after 30 days should be escalated or moved to a project file

---

## Sync Protocol (Multi-Node)

For multi-node setups, consistent synchronization prevents knowledge drift.

### Push Triggers

Commit and push your node's memory changes when:

- A significant session ends (architecture decisions, new rules)
- New feedback or correction is recorded
- A project status changes materially
- Shared conventions are updated

### Pull Triggers

Pull the latest memory hub when:

- A new session starts (always)
- Before performing cross-node tasks
- Before making changes to `shared/` files
- After another node signals it has pushed updates

### Conflict Resolution

Merge conflicts in memory files are disruptive. Prevent them with these rules:

1. **Each node only writes to its own folder.** Node 1 never edits files in `node-2/`.
2. **Designate one node as the authority for `shared/`.** Other nodes propose changes (via comments, issues, or a staging file), and the authority node applies them.
3. **Use append-only patterns where possible.** Adding a new entry to a list is conflict-free. Editing existing entries risks conflicts.
4. **If a conflict does occur:** The most recent timestamp wins, and the conflict is logged in `sync-log.md`.

### Sync Log

Maintain a `sync-log.md` at the repository root for auditability:

```markdown
# Sync Log

## 2026-03-15 14:32 UTC -- node-1
- Updated: shared/conventions.md (added Docker naming rules)
- Updated: node-1/memory/project_webapp.md (status change)

## 2026-03-15 09:15 UTC -- node-2
- Added: node-2/memory/feedback_deploy_rollback.md
- Updated: node-2/MEMORY.md (new feedback entry)
```

---

## Common Pitfalls

### 1. Monolithic MEMORY.md That Grows Forever

**Problem:** Dumping everything into one file until it exceeds the context window.
**Solution:** Use MEMORY.md as an index only. Store actual content in individual files. Archive aggressively.

### 2. No Scheduled Reviews

**Problem:** Memory files go stale. The assistant acts on outdated information and makes wrong decisions.
**Solution:** Set a recurring calendar reminder (twice per week). Spend 10 minutes scanning for stale content.

### 3. Storing Secrets in Memory Files

**Problem:** API keys, passwords, tokens, or credentials stored in memory files -- especially dangerous if synced via Git.
**Solution:** NEVER store secrets in memory files. Use environment variables, secret managers, or encrypted vaults. If you find a secret in a memory file, rotate it immediately and remove it.

### 4. No Backup Strategy

**Problem:** Local-only memory files are a single point of failure. A disk failure or accidental deletion loses everything.
**Solution:** Use a private Git repository. Even for single-node setups, pushing to a remote gives you version history and disaster recovery.

### 5. Inconsistent Taxonomy

**Problem:** Some files are labeled "project," others "work," others have no category. Finding anything requires reading every file.
**Solution:** Pick your memory types (system, feedback, project, reference, shared) and enforce them from day one. Use filename prefixes: `system_`, `feedback_`, `project_`, `reference_`.

### 6. Session Notes Without Structure

**Problem:** Session summaries that say "worked on the API" with no detail about what was decided or what is still open.
**Solution:** Always use the three-part format: Key Decisions, Changes Made, Open Items. If a session summary does not have at least one entry in each section, it is not worth writing.

### 7. Cross-Node Drift

**Problem:** In multi-node setups, nodes stop syncing regularly. After a week, they have contradictory information.
**Solution:** Automate sync with a LaunchAgent or cron job. Pull at session start, push at session end. Make it automatic so it cannot be forgotten.

---

## LaunchAgent Template for Auto-Sync (macOS)

Save the following as `~/Library/LaunchAgents/com.openclaw.memory-sync.plist` to run a daily sync automatically.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.memory-sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>
cd "$HOME/Developer/memory-hub" &amp;&amp; \
git pull --rebase origin main &amp;&amp; \
git add -A &amp;&amp; \
git diff --cached --quiet || \
  git commit -m "auto-sync: $(hostname) $(date +%Y-%m-%dT%H:%M:%S)" &amp;&amp; \
git push origin main
        </string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>6</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/memory-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/memory-sync-error.log</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

**To install:**
```bash
cp com.openclaw.memory-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.openclaw.memory-sync.plist
```

**For Linux (cron equivalent):**
```bash
# Add to crontab -e
0 6 * * * cd ~/Developer/memory-hub && git pull --rebase origin main && git add -A && git diff --cached --quiet || git commit -m "auto-sync: $(hostname) $(date +\%Y-\%m-\%dT\%H:\%M:\%S)" && git push origin main >> /tmp/memory-sync.log 2>&1
```

---

## Recommended SOP: Memory Sync

Use this standard operating procedure as a starting template. Adapt the specifics to your setup.

### Daily Routine

| Time        | Action                                              |
|-------------|-----------------------------------------------------|
| Session start | Pull latest from memory hub (`git pull --rebase`)  |
| During session | Write session summaries for significant decisions |
| Session end | Commit and push memory changes                      |

### Weekly Review (15 minutes)

1. **Scan project files:** Is every project file still accurate? Archive completed work.
2. **Check open items:** Are session summary open items resolved? Move resolved items to "done" or archive the summary.
3. **Review shared files (multi-node):** Are conventions and infrastructure docs current?
4. **Check MEMORY.md size:** Approaching the 18,000 character limit? Archive low-priority entries.

### Monthly Review (30 minutes)

1. **Audit feedback files:** Are lessons still relevant? Has the underlying system changed?
2. **Audit reference files:** Are external IDs, URLs, and configurations still correct?
3. **Review archives:** Is anything archived that should be restored to active memory?
4. **Sync log review (multi-node):** Are all nodes syncing regularly? Investigate gaps.

### On Incident

When something goes wrong because of missing or incorrect memory:

1. **Immediately** create or update the relevant memory file
2. **Tag it as feedback** with the date and a brief description of what went wrong
3. **Push to the memory hub** so all nodes learn the lesson
4. **Add it to MEMORY.md** index with a clear, searchable title

---

## Quick Reference

| Task                          | Command / Action                                    |
|-------------------------------|-----------------------------------------------------|
| Start a session               | `cd memory-hub && git pull --rebase origin main`    |
| End a session                 | `git add -A && git commit -m "session end" && git push` |
| Archive a memory file         | `mv memory/file.md archives/file.md`                |
| Check memory size             | `wc -c MEMORY.md` (target: under 18,000 chars)      |
| Find stale files              | `find memory/ -mtime +30 -name "*.md"`              |
| View sync log                 | `cat sync-log.md`                                   |

---

*This guide is based on real-world patterns from running AI assistants across multiple machines. Start simple (single node, five memory files), and scale up as your usage grows. The most important thing is not the structure -- it is the habit of reviewing and maintaining your memory files regularly.*
