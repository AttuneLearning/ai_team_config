---
name: pre-implementation
type: advisory
auto_dismiss: 15000
triggers:
  - keywords: [implement, create, add, build, develop]
  - file_patterns: ["*.routes.ts", "*.controller.ts", "*.service.ts", "*.model.ts"]
---

# Pre-Implementation Hook

Advisory reminder before implementation begins.

## Display

```
+--------------------------------------------------+
|  Load context before implementing?               |
|                                                  |
|  Run `/context` to load relevant ADRs/patterns   |
|                                                  |
|  [Load Context]  [Skip]     (auto-dismiss: 15s)  |
+--------------------------------------------------+
```

## Behavior

- **Trigger**: Detected implementation intent + no recent `/context` call
- **Auto-dismiss**: 15 seconds
- **Default action**: Skip (non-blocking)
- **Cooldown**: 30 minutes after dismiss

## Detection Logic

```
IF (
  message contains implementation keywords
  AND no /context in last 5 messages
  AND not in planning mode
)
THEN show advisory
```

## Actions

| Button | Action |
|--------|--------|
| Load Context | Execute `/context` with auto-detected work type |
| Skip | Dismiss, set 30-min cooldown |
| (timeout) | Same as Skip |

## Configuration

Projects can customize in `.claude/hooks.json`:

```json
{
  "pre-implementation": {
    "enabled": true,
    "auto_dismiss": 15000,
    "cooldown": 1800000,
    "keywords": ["implement", "create", "add", "build"]
  }
}
```
