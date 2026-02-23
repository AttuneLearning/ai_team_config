---
name: post-implementation
type: advisory
auto_dismiss: 15000
triggers:
  - keywords: [done, complete, finished, implemented]
  - events: [commit, test_pass]
---

# Post-Implementation Hook

Advisory reminder after implementation phase completes.

## Display

```
+--------------------------------------------------+
|  Post-implementation checklist:                  |
|                                                  |
|  1. Comms response sent? (if triggered by        |
|     inbound message, send /comms send)           |
|  2. Capture learnings? (run /reflect)            |
|                                                  |
|  [Comms + Reflect]  [Reflect]  [Skip]  (15s)     |
+--------------------------------------------------+
```

## Behavior

- **Trigger**: Implementation completion signals
- **Auto-dismiss**: 15 seconds
- **Default action**: Skip (non-blocking)
- **Cooldown**: Until next implementation cycle

## Detection Logic

```
IF (
  (message indicates completion OR commit detected OR tests pass)
  AND files were modified in session
  AND (no /reflect in current cycle OR no comms response sent for inbound-triggered work)
)
THEN show advisory
```

### Comms Response Detection

```
IF (
  current issue was created from an inbound message
  AND no outbound message was sent to the originating team in this cycle
)
THEN comms_response_needed = true
```

## Actions

| Button | Action |
|--------|--------|
| Comms + Reflect | Prompt `/comms send` to originating team, then execute `/reflect` |
| Reflect | Execute `/reflect` on current session (use when no comms response needed) |
| Skip | Dismiss, mark cycle as reflected |
| (timeout) | Same as Skip |

**Note:** If `comms_response_needed` is true, the "Comms + Reflect" button is highlighted as the recommended action. Skipping comms response when one is needed should produce a warning.

## Implementation Cycle

A cycle is defined as:
- Start: First file modification after idle or `/context`
- End: Commit, explicit completion, or 2+ hours idle

## Configuration

```json
{
  "post-implementation": {
    "enabled": true,
    "auto_dismiss": 15000,
    "require_on_commit": false,
    "min_files_changed": 2
  }
}
```
