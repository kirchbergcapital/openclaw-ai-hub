# Operational Framework: Priority Map + Auto-Resolver

A practical guide to giving your AI assistant clear rules for what matters and what to do about it.

---

## Why You Need an Operational Framework

Without explicit rules, your AI assistant operates in one of two failure modes:

1. **Over-asking** — every minor decision triggers a question, flooding you with interrupts
2. **Over-acting** — the assistant takes autonomous action on things that needed your judgment

Both waste your time. The fix is two files that work together:

- **priority-map.md** defines what matters, who matters, and how urgent each category is
- **auto-resolver.md** defines what the assistant can handle on its own versus what needs your input

These two files turn vague intent into deterministic behavior. Your assistant reads them on every cycle and routes work accordingly.

This approach is inspired by the clawchief concept (credit: [github.com/snarktank/clawchief](https://github.com/snarktank/clawchief)), adapted here for multi-node OpenClaw deployments.

---

## Priority Map (Template)

Copy this template to `shared/priority-map.md` and customize it for your situation.

```markdown
# Priority Map

## Urgency Levels

| Level | Name       | Definition                                                    | Response Time |
|-------|------------|---------------------------------------------------------------|---------------|
| P0    | Fire       | Revenue at risk, legal exposure, system down, safety issue    | Immediate     |
| P1    | Today      | Commitment due today, blocked teammate, time-sensitive reply  | Within 2 hrs  |
| P2    | This Week  | Active project work, follow-ups, scheduled deliverables       | Within 24 hrs |
| P3    | Backlog    | Nice-to-have, research, optimization, low-stakes admin        | When capacity allows |

## Action Modes

| Mode             | Behavior                                                         |
|------------------|------------------------------------------------------------------|
| interrupt        | Stop current work. Notify the principal immediately.             |
| handle+summarize | Resolve it autonomously, then provide a brief summary.           |
| draft+ask        | Prepare a response or action, present it for approval.           |
| queue            | Log it to the task system. Do not act yet.                       |
| ignore           | Drop it. No log entry needed.                                    |

## People

Define how to treat messages and tasks from different people.

| Category            | Who (customize these)            | Default Urgency | Default Mode     |
|---------------------|----------------------------------|-----------------|------------------|
| Principal           | [YOUR NAME]                      | —               | Follow explicit instructions |
| Family              | [FAMILY MEMBER 1], [MEMBER 2]    | P1              | interrupt        |
| Key Operators       | [ASSISTANT], [CTO], [COO]        | P1              | handle+summarize |
| Board / Investors   | [INVESTOR 1], [BOARD MEMBER 1]   | P1              | draft+ask        |
| Active Prospects    | [PROSPECT 1], [PROSPECT 2]       | P2              | draft+ask        |
| Meeting Counterparts| [RECENT CONTACT 1], [CONTACT 2]  | P2              | queue            |
| Service Providers   | [ACCOUNTANT], [LAWYER], [VENDOR] | P2              | queue            |
| Unknown / Cold      | Anyone not listed above          | P3              | queue            |

## Programs

Map your business areas to urgency and action modes.

| Program             | Scope                                          | Default Urgency | Default Mode     |
|---------------------|-------------------------------------------------|-----------------|------------------|
| Revenue             | Deals in progress, invoices, payments            | P0              | interrupt        |
| EA / Calendar       | Scheduling conflicts, meeting prep, reminders    | P1              | handle+summarize |
| Board / Investors   | Reporting, data requests, updates                | P1              | draft+ask        |
| Legal / Compliance  | Contracts, NDAs, regulatory items                | P1              | draft+ask        |
| Business Dev        | Outreach, proposals, partnership follow-ups      | P2              | draft+ask        |
| Marketing / Content | Blog posts, social media, newsletters            | P2              | queue            |
| Product / Ops       | Feature requests, bug reports, infra tasks       | P2              | queue            |
| Personal            | Health, errands, personal projects               | P3              | queue            |

## Default Routing Rules

1. If sender is Family and content mentions health or safety → P0, interrupt
2. If sender is Board/Investors and content is a direct question → P1, draft+ask
3. If a calendar conflict is detected for today → P1, handle+summarize
4. If an invoice is overdue or a payment failed → P0, interrupt
5. If the message is a newsletter, marketing email, or automated notification → ignore
6. If a task has a deadline within 24 hours and no progress logged → P1, handle+summarize
7. If uncertain about urgency, default to P2 + queue (never guess on P0)

## Things to Ignore

- Newsletters and bulk marketing emails
- Social media notifications (likes, follows, reposts)
- Automated build/deploy success notifications (only surface failures)
- Calendar invites from unknown senders with no context
- Promotional offers and upsell emails from SaaS vendors
```

---

## Auto-Resolver (Template)

Copy this template to `shared/auto-resolver.md` and adjust the boundaries to your comfort level.

```markdown
# Auto-Resolver

## Core Principle

When an item comes in, resolve the obvious next step — do not just summarize it.
Summarizing without acting is a polite way of doing nothing.

## Resolution Modes

| Mode         | When to Use                                              | Example                                  |
|--------------|----------------------------------------------------------|------------------------------------------|
| auto-resolve | Low risk, clear next step, reversible action             | File a task, send a standard reply, update a status |
| draft+ask    | Medium risk, needs principal's voice or judgment         | Draft an email to an investor, propose a meeting time |
| escalate     | High risk, irreversible, financial, legal, or ambiguous  | Sign a contract, transfer funds, fire someone |
| ignore       | Matches the ignore list in priority-map.md               | Newsletter, spam, automated notification |

## Safe Auto-Resolve Conditions

ALL of these must be true before auto-resolving:

1. The action is **reversible** (can be undone or corrected without damage)
2. The action is **low-stakes** (no financial, legal, or reputational risk)
3. The action has a **clear precedent** (you have done this exact type of action before)
4. The action does **not send external communication** (no emails, messages, or posts)
5. The action is **within scope** of the node's permissions (see Multi-Node section)

If ANY condition fails → escalate to draft+ask or escalate mode.

## Auto-Resolve Examples

Things you CAN auto-resolve (when all conditions above are met):
- Create a task in the task system from an action item
- Update a project status based on completed work
- File meeting notes into the correct project folder
- Flag a calendar conflict and block the time
- Summarize a document and attach the summary to the relevant task
- Archive a completed task

Things that ALWAYS require draft+ask:
- Any reply to an external person
- Scheduling or rescheduling a meeting
- Committing and pushing code to a shared repository
- Updating a shared document that others rely on
- Any action involving money, contracts, or legal matters

Things that ALWAYS require escalate (notify principal immediately):
- System security alerts or unauthorized access attempts
- Failed payments or billing issues
- Legal notices or compliance deadlines
- Any P0 item from the priority map
- Conflicting instructions from two key operators

## Source-of-Truth Rule

Never resolve an item based on memory alone. Always verify against:
- The actual email, message, or document (not your summary of it)
- The current state of the task system (not what you remember it was)
- The latest version of any referenced file (not a cached version)

If you cannot access the source of truth, do not resolve. Queue the item and note
what you need to verify.

## Output Style

- **Be brief.** A resolution summary should be 1-3 sentences.
- **Lead with what you did**, not what you analyzed.
  - Good: "Created task: Follow up with [Name] re: proposal. Due: Friday."
  - Bad: "I noticed that the email from [Name] mentions a proposal that seems
    important, so I think we should probably follow up..."
- **No status updates for ignored items.** If it matched the ignore list, drop it silently.
- **Group resolutions** when reporting. Do not send one notification per item.
```

---

## Meeting Notes Ingestion

Meeting notes are not passive records. Treat them as live signal sources that generate work.

**Processing steps:**

1. **Extract** structured items from the raw notes:
   - Action items (who owes what, by when)
   - Follow-ups (conversations to continue)
   - Deadlines (explicit or implied commitments)
   - Promises made (by you or to you)
   - Decisions reached (and their context)

2. **Route** each extracted item through the priority map:
   - Who is involved? Check the People table for urgency.
   - What program does it fall under? Check the Programs table.
   - Assign the appropriate urgency level and action mode.

3. **Resolve** each item through the auto-resolver:
   - Action items with clear owners and deadlines → auto-resolve (create task)
   - Follow-ups requiring your voice → draft+ask
   - Commitments involving money or contracts → escalate

4. **A meeting note is "processed"** only when every extracted item has been routed to the task system, drafted, or escalated. If items remain unprocessed, the note stays in the active queue.

**Tip:** Structure your meeting notes with clear markers (`ACTION:`, `FOLLOW-UP:`, `DECISION:`) to make extraction reliable. The more structured the input, the better the auto-resolver performs.

---

## Multi-Node Considerations

If you run multiple OpenClaw nodes (for example, a primary workstation and a secondary server), each node needs clear boundaries.

**Principles:**

1. **All nodes read the same priority-map.md and auto-resolver.md** from the shared directory. There is one source of truth for priorities and rules.

2. **Each node may have different auto-resolve permissions.** For example:
   - Primary node: can auto-resolve tasks, draft communications, manage files
   - Secondary node: can auto-resolve background jobs, but must escalate anything involving external communication or admin actions

3. **Designate one node as the security/admin authority.** Only this node should:
   - Modify access controls or permissions
   - Handle credential rotation
   - Push to protected branches
   - Execute irreversible infrastructure changes

4. **Cross-node task handoff** works through the shared task system. If Node A identifies work that only Node B can handle, it creates a task tagged with the target node. Node B picks it up on its next cycle.

5. **Conflict resolution:** If two nodes attempt to act on the same item, the node with higher permissions wins. If permissions are equal, the first node to log the resolution wins. Design your routing rules to avoid this.

**Example node permission table:**

```markdown
| Action                  | Primary Node | Secondary Node |
|-------------------------|--------------|----------------|
| Create tasks            | yes          | yes            |
| Draft external messages | yes          | no — queue     |
| Push to repos           | yes          | no — queue     |
| Modify security config  | yes          | no — escalate  |
| Run background jobs     | yes          | yes            |
| Auto-archive completed  | yes          | yes            |
```

---

## Getting Started

1. **Copy the templates** above into your workspace:
   - `shared/priority-map.md`
   - `shared/auto-resolver.md`

2. **Customize the People section** with real names and categories. Be specific — the more precisely you define who matters and how much, the better the routing works.

3. **Customize the Programs section** for your actual business areas. Remove what does not apply. Add what is missing.

4. **Set your auto-resolve boundaries.** Start conservative (more draft+ask, less auto-resolve). Loosen the boundaries as you build trust in the system. You can always tighten them again.

5. **Place both files where your agent reads them.** In an OpenClaw setup, this is typically `shared/` or `workspace/`. The exact path depends on your configuration.

6. **Reference both files in your HEARTBEAT.md.** Your heartbeat cycle should include:
   ```
   - Read shared/priority-map.md for current routing rules
   - Read shared/auto-resolver.md for resolution permissions
   - Process new inputs through priority-map → auto-resolver pipeline
   ```

7. **Review and adjust weekly.** After your first week, check:
   - Were any items auto-resolved that should have been escalated?
   - Were you interrupted for things that could have been queued?
   - Are there new people or programs that need entries?

The framework works when you stop thinking about routing and your assistant handles it correctly by default. That is the goal.
