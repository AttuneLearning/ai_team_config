---
name: comms
description: Manage inter-team communication, issues, and coordination
argument-hint: "[check|send|issue|status|move|archive]"
---

# Dev Communication Skill

Manage inter-team communication, issues, and coordination.

## Usage

```
/comms [action] [options]
```

## Team Context Resolution

Determine your team identity before any action:
1. Read `./active-role.json` (canonical project role file)
2. If unavailable, check platform mirrors:
   - `.codex-workflow/config/active-role.json`
   - `.codex-workflow/config/active-agent-role.json` (legacy alias)
   - `.claude/active-role.json`
3. If still unavailable, infer from `dev_communication/` team directories
4. Use the role's `team_id` to resolve paths (inbox, issues, status)

Path variables used below:
- `{my_inbox}` — `dev_communication/{my_team}/inbox/`
- `{my_issues}` — `dev_communication/{my_team}/issues/`
- `{other_inbox}` — `dev_communication/{other_team}/inbox/`
- `{my_status}` — `dev_communication/{my_team}/status.md`

## Actions

Based on the user's request or argument, perform one of these actions:

Header normalization for new messages:
- Use exact sub-team values in `From`/`To`: `Backend-Dev`, `Backend-QA`, `Frontend-Dev`, `Frontend-QA`.
- Avoid generic labels such as `API Team` or `UI Team` in newly authored messages.

---

### 1. CHECK (default if no action specified)

Check inbox, pending issues, and team status.

**Trigger:** `/comms`, `/comms check`, "check messages", "any updates?"

**Steps:**
1. List files in `{my_inbox}`
2. List files in `{my_issues}/queue/`
3. List files in `{my_issues}/active/`

Project policy:
- Default check scope is team-local only.
- Include cross-team folders only when explicitly requested by the user.

**Output format:**
```
## Comms Status

### {My Team} Inbox
- [filename] - [first line/subject]
- (or "No pending messages")

### {My Team} Issue Queue
- [ISS-xxx] - [title]
- (or "No pending issues")

### {My Team} Active Issues
- [ISS-xxx] - [title] - [status]
- (or "No active issues")
```

---

### 2. SEND

Send a message to another team.

**Trigger:** `/comms send`, "send message to {team}", "notify {team} team"

**Steps:**
1. Ask for message type: Request or Response
2. Ask for priority: Critical, High, Medium, Low
3. Ask for subject
4. Ask for content (or let user provide)
5. Use template from `dev_communication/templates/`
6. Generate filename: `YYYY-MM-DD_{subject_slug}.md`
7. Save to `{other_inbox}`
8. Confirm sent

**If responding to a message:**
1. Ask which message this responds to
2. Use response template
3. Include `In-Response-To:` field
4. Optionally move original + response to `archive/`

---

### 3. ISSUE

Create a new issue.

**Trigger:** `/comms issue`, "create issue", "new issue"

**Steps:**
1. Scan `{my_issues}` across queue/active/completed to determine next issue number
2. Ask for: title, priority, description, requirements
3. Use template from `dev_communication/templates/issue-template.md`
4. Generate filename: `{ISSUE_PREFIX}-{NNN}_{title_slug}.md`
5. Save to `{my_issues}/queue/`
6. Set `Status: QUEUE` in issue metadata
7. Confirm created

**For cross-team issues:**
1. Keep issue ownership local by default (create in your team's queue)
2. Send cross-team message to the other team's inbox for dependency/request tracking
3. Link with `Related:` field

---

### 4. STATUS

Update team status.

**Trigger:** `/comms status`, "update status", "set focus"

**Steps:**
1. Review current active issues for your team.
2. Ask what to update: Current focus, Active issues, Blockers, Notes
3. Update `{my_status}`
4. Include cross-team status only when explicitly requested.

---

### 5. MOVE

Move an issue through lifecycle.

**Trigger:** `/comms move ISS-xxx`, "move issue to active", "complete ISS-xxx"

**Steps:**
1. Find the issue file
2. Ask target status: queue, active, completed
3. Apply strict folder-status mapping:
   - `queue` -> `Status: QUEUE` and path `issues/queue/`
   - `active` -> `Status: ACTIVE` and path `issues/active/`
   - `completed` -> `Status: COMPLETE` and path `issues/completed/`
4. Update status field and move file in the same action
5. If completing:
   - Ask for completion notes
   - Update completion section
   - If cross-team, ask if response message needed
6. Confirm moved

**Completion ownership (mandatory):**
- Only the QA sub-team may move issues to `completed/`.
- Dev sub-teams move issues from `queue/` to `active/` only.
- After dev verification, issues remain in `active/` until QA independently verifies and moves them.
- If a dev agent attempts to move an issue to `completed/`, reject the action and remind them that QA owns this step.

---

### 6. ARCHIVE

Archive completed message threads.

**Trigger:** `/comms archive`, "archive messages"

**Steps:**
1. List messages in `{my_inbox}` and `{other_inbox}`
2. Ask which thread to archive (or auto-detect completed)
3. Create folder: `dev_communication/archive/YYYY-MM-DD_{thread_subject}/`
4. Move related messages to archive folder
5. Confirm archived

---

## File Locations

```
dev_communication/
├── {team}/
│   ├── inbox/                    # Team inbox (messages from other teams)
│   └── issues/
│       ├── queue/                # Pending issues
│       ├── active/               # In-progress issues
│       └── completed/            # Completed issues
├── shared/
│   ├── architecture/             # ADRs, gaps, suggestions
│   ├── guidance/                 # Development principles, role guidance
│   ├── plans/                    # Shared plans
│   ├── specs/                    # Feature specs
│   └── contracts/                # Endpoint contracts
├── templates/                    # Message and issue templates
└── archive/                      # Archived message threads
```

## Auto-Suggestions

After completing work, suggest:
- "This affects {other-team} team. Send a notification? (`/comms send`)"
- "Issue complete. Move to completed? (`/comms move`)"
- "New requirement discovered. Create issue? (`/comms issue`)"
