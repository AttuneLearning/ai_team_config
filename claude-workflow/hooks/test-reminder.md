---
name: test-reminder
type: advisory
auto_dismiss: 15000
triggers:
  - events: [implementation_complete]
  - keywords: [ready, done implementing]
---

# Test Reminder Hook

Advisory reminder per ADR-DEV-001 (Lazy TDD).

## Display

```
+--------------------------------------------------+
|  Tests needed (ADR-DEV-001: Lazy TDD)            |
|                                                  |
|  T1: Write tests for this implementation phase   |
|                                                  |
|  [Write Tests]  [Skip]      (auto-dismiss: 15s)  |
+--------------------------------------------------+
```

## Behavior

- **Trigger**: Implementation phase complete, no tests written
- **Auto-dismiss**: 15 seconds
- **Default action**: Skip (non-blocking)
- **Escalation**: After 3 skips, reminder becomes persistent

## Detection Logic

```
IF (
  implementation files modified
  AND no test files modified
  AND not explicitly deferred
)
THEN show advisory
```

## Test Tiers (ADR-DEV-001)

| Tier | When | Scope |
|------|------|-------|
| T1 | After each phase | Unit + integration for phase |
| T2 | Milestone | Cross-feature integration |
| T3 | Always | `tsc --noEmit` type check |

## Actions

| Button | Action |
|--------|--------|
| Write Tests | Load testing-endpoint or testing-bugfix pattern |
| Skip | Dismiss, increment skip counter |
| (timeout) | Same as Skip |

## Configuration

```json
{
  "test-reminder": {
    "enabled": true,
    "auto_dismiss": 15000,
    "max_skips": 3,
    "escalate_after_skips": true
  }
}
```
