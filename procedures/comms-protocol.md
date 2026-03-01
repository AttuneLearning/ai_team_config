# Cross-Team Communication Protocol

**Applies to:** All roles
**Machine-readable:** `teams/protocol.yaml`

---

## Principles

1. **Every inbound message that triggers work MUST get a response.** No silent consumption.
2. **Backend defines contracts, frontend consumes them.** Contract changes flow backend → frontend.
3. **Never write normalizers or transforms.** If the response doesn't match, that's a contract gap — send a message.
4. **Only QA moves issues to completed.** Dev hands off; QA verifies and completes.
5. **Issues stay local.** Create issues in YOUR team's queue. Send cross-team messages for dependencies.

---

## Message Flow

```
Frontend-Dev ──request──→ Backend-Dev inbox
Backend-Dev ──contract──→ Frontend-Dev inbox
Backend-Dev ──handoff───→ Backend-QA (via issue status)
Backend-QA  ──verdict───→ Backend-Dev inbox
Frontend-Dev ──handoff──→ Frontend-QA (via issue status)
Frontend-QA  ──verdict──→ Frontend-Dev inbox
```

---

## File Locations

```
dev_communication/
├── {team}/
│   ├── inbox/                    # Incoming messages from other teams
│   └── issues/
│       ├── queue/                # Pending issues (not yet started)
│       ├── active/               # In-progress issues
│       └── completed/            # QA-approved issues (QA moves here)
├── shared/
│   ├── architecture/decisions/   # ADRs
│   ├── guidance/                 # Role guidance documents
│   ├── plans/                    # Shared implementation plans
│   └── contracts/types/          # Shared contract DTOs (source of truth)
├── templates/                    # Message and issue templates
└── archive/                      # Completed threads
```

---

## Message Headers

Use exact sub-team values:
- `Backend-Dev`, `Backend-QA`, `Frontend-Dev`, `Frontend-QA`
- Never use generic labels like "API Team" or "UI Team"

---

## Contract Rules (ADR-DEV-004)

**Prohibited patterns:**
- Silent field renames (e.g., `order` → `sequence` in a transform layer)
- Silent format conversions (e.g., `in_progress` → `in-progress` in a mapping function)
- Derived fields (e.g., inferring `dataSource` from `playerType`)
- Fallback defaults that mask missing data (e.g., `?? 'quiz'`, `?? 'in-progress'`)

**When a contract is insufficient:**
1. Do NOT work around it locally
2. Send a message to the contract-owning team describing:
   - What is needed
   - What the contract currently provides
   - Which endpoint is affected
   - Reference the contract file
3. Wait for the contract update before building against it

---

## Issue Lifecycle Ownership

| Action | Who Can Do It |
|--------|--------------|
| Create issue in own queue | Dev, QA |
| Move queue/ → active/ | Dev |
| Move active/ → completed/ | **QA only** |
| Set Status: COMPLETE | **QA only** |
| Send messages to other team | Any role |
| Define/update contracts | Backend-Dev |
| Request contract changes | Frontend-Dev |
