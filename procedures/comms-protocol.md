# Cross-Team Communication Protocol

## Principles

1. Every inbound message that triggers work MUST get a response
2. Backend defines contracts, frontend consumes them (ADR-DEV-004)
3. Never write normalizers or transforms — contract gaps are messages, not code
4. Only QA moves issues to completed

## Message Flow

```
Frontend-Dev ──request──→ Backend-Dev inbox
Backend-Dev ──contract──→ Frontend-Dev inbox
Dev ──handoff──→ QA (via issue status + inbox message)
QA ──verdict──→ Dev inbox
```

## Ownership

| Action | Owner |
|--------|-------|
| Create issues in own queue | Dev, QA |
| Move queue/ → active/ | Dev |
| Move active/ → completed/ | **QA only** |
| Set Status: COMPLETE | **QA only** |
| Define/update contracts | Backend-Dev |
| Request contract changes | Frontend-Dev |
| Send cross-team messages | Any role |

## Contract Rules (ADR-DEV-004)

**Prohibited:** silent field renames, silent format conversions, derived fields, fallback defaults masking missing data.

**When contract is insufficient:** send a message describing the gap. Do NOT work around it locally.

## Message Headers

Use exact values: `Backend-Dev`, `Backend-QA`, `Frontend-Dev`, `Frontend-QA`.

## File Layout

```
dev_communication/{team}/inbox/              ← unprocessed messages
dev_communication/{team}/inbox/completed/    ← handled messages
dev_communication/{team}/issues/{queue,active,completed}/
dev_communication/shared/contracts/types/    ← shared DTOs (source of truth)
```
