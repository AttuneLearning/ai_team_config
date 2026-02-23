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
1. List files in `dev_communication/backend/inbox/` (API team's inbox — messages from UI)
2. List files in `dev_communication/backend/issues/queue/`
3. List files in `dev_communication/backend/issues/active/`

Project policy:
- Default check scope is team-local only.
- In API/backend projects, `/comms` checks only backend inbox/issues by default.
- Include frontend/cross-team folders only when explicitly requested by the user.

**Output format:**
```
## Comms Status

### Backend Inbox (backend/inbox/)
- [filename] - [first line/subject]
- (or "No pending messages")

### Backend Issue Queue (backend/issues/queue/)
- [ISS-xxx] - [title]
- (or "No pending issues")

### Backend Active Issues (backend/issues/active/)
- [ISS-xxx] - [title] - [status]
- (or "No active issues")

### Frontend Inbox (frontend/inbox/)
- [filename] - [first line/subject]
- (or "No pending messages")

### Frontend Issue Queue (frontend/issues/queue/)
- [ISS-xxx] - [title]
- (or "No pending issues")

### Frontend Active Issues (frontend/issues/active/)
- [ISS-xxx] - [title] - [status]
- (or "No active issues")
```

Note: frontend sections are optional and should only be emitted when user explicitly asks for cross-team status.

---

### 2. SEND

Send a message to the other team.

**Trigger:** `/comms send`, "send message to {team}", "notify {team} team"

**Steps:**
1. Ask for message type: Request or Response
2. Ask for priority: Critical, High, Medium, Low
3. Ask for subject
4. Ask for content (or let user provide)
5. Use template from `dev_communication/templates/`
6. Generate filename: `YYYY-MM-DD_{subject_slug}.md`
7. Save to `dev_communication/frontend/inbox/` (if sending to UI) or `dev_communication/backend/inbox/` (if sending to API)
8. Confirm sent

**If responding to a message:**
1. Ask which message this responds to
2. Use response template
3. Include `In-Response-To:` field
4. Optionally move original + response to `archive/`

---

### 3. ISSUE

Create a new issue.

**Trigger:** `/comms issue`, "create issue", "new {team} issue"

**Steps:**
1. Scan `dev_communication/backend/issues/` and `dev_communication/frontend/issues/` to determine next issue number
2. Ask for: title, priority, description, requirements
3. Use template from `dev_communication/templates/issue-template.md`
4. Generate filename: `{TEAM}-ISS-{NNN}_{title_slug}.md`
5. Save to `dev_communication/backend/issues/queue/` (API issues) or `dev_communication/frontend/issues/queue/` (UI issues)
6. Set `Status: QUEUE` in issue metadata
7. Confirm created

**For cross-team issues:**
1. Keep issue ownership local by default (create in your team's queue)
2. Send cross-team message to the other team's inbox for dependency/request tracking
3. Link with `Related:` field
4. If the user explicitly requests a mirrored issue in the other team queue, create it and cross-link both issues

---

### 4. STATUS

Update team status.

**Trigger:** `/comms status`, "update status", "set focus"

**Steps:**
1. Review current active issues for the active team by default.
2. Ask what to update:
   - Current focus
   - Active issues
   - Blockers
   - Notes
3. Update active team status file (`dev_communication/backend/status.md` or `dev_communication/frontend/status.md`).
4. Include cross-team status updates only when explicitly requested by the user.

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

**Completion rule (mandatory):**
- Completed issues must not remain in `queue/` or `active/`.
- Completion is only valid after both status update and move to `completed/`.
- Folder and status values must always match (`QUEUE`, `ACTIVE`, `COMPLETE`).

**Completion ownership (mandatory):**
- Only the QA team or QA sub-team may move issues to `completed/`.
- Dev teams move issues from `queue/` to `active/` only.
- After dev verification, issues remain in `active/` until QA independently verifies and moves them.
- If a dev agent attempts to move an issue to `completed/`, reject the action and remind them that QA owns this step.

---

### 6. ARCHIVE

Archive completed message threads.

**Trigger:** `/comms archive`, "archive messages"

**Steps:**
1. List messages in `dev_communication/backend/inbox/` and `dev_communication/frontend/inbox/`
2. Ask which thread to archive (or auto-detect completed)
3. Create folder: `dev_communication/archive/YYYY-MM-DD_{thread_subject}/`
4. Move related messages to archive folder
5. Confirm archived

---

## File Locations

```
dev_communication/
├── backend/
│   ├── inbox/                    # API team's inbox (messages from UI team)
│   └── issues/
│       ├── queue/                # Pending API issues
│       ├── active/               # In-progress API issues
│       └── completed/            # Completed API issues
├── frontend/
│   ├── inbox/                    # UI team's inbox (messages from API team)
│   │   └── completed/            # Acknowledged/completed messages
│   └── issues/
│       ├── queue/                # Pending UI issues
│       ├── active/               # In-progress UI issues
│       └── completed/            # Completed UI issues
├── shared/
│   ├── architecture/             # ADRs, gaps, suggestions
│   ├── guidance/                 # Development principles, checklists
│   ├── plans/                    # Shared plans
│   └── specs/                    # Feature specs
├── templates/                    # Message and issue templates
└── archive/                      # Archived message threads
```

## Team Context

Determine team from active workflow config:
- Read `.codex-workflow/config/active-team.json` (or local equivalent) for current team and paths.
- If unavailable, infer from repository `dev_communication/<team>/` structure.

## Auto-Suggestions

After completing work, suggest:
- "This affects {other-team} team. Send a notification? (`/comms send`)"
- "Issue complete. Move to completed? (`/comms move`)"
- "New requirement discovered. Create issue? (`/comms issue`)"
