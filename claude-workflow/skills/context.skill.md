---
name: context
trigger: /context
description: Load relevant ADRs, patterns, and memory before implementation
auto_trigger: false
argument-hint: "[quick|work-type|topic]"
---

# Context Loading Skill

Pre-implementation context loading. Combines ADR lookup, pattern loading, and memory recall.

## Usage

```
/context                    # Auto-detect work type from conversation
/context quick              # Quick orientation (memory + recent activity only)
/context new-endpoint       # Explicit work type
/context certificates       # Search by topic
```

## Quick Mode (`/context quick`)

Fast orientation for session start or context recovery:

1. Read `ai_team_config/memory_store/memory-log.md` for recent activity
2. Read `ai_team_config/memory_store/context/project-overview.md`
3. If topic mentioned, search `ai_team_config/memory_store/` for keywords
4. Output brief summary:
   ```
   ## Context Loaded
   **Recent Activity:** [from memory-log]
   **Relevant:** [matching entities/patterns]
   ```

## Full Mode (default)

1. **Detect Work Type** from conversation keywords:
   | Work Type | Keywords |
   |-----------|----------|
   | new-endpoint | route, endpoint, api, controller |
   | new-model | model, schema, collection, mongoose |
   | bug-fix | fix, bug, issue, broken, error |
   | auth-change | auth, permission, access, role |
   | testing | test, spec, jest, coverage |

2. **Load ADRs** (max 3) — decision section only, skip rationale unless requested

3. **Load Patterns** (max 4) from `ai_team_config/memory_store/patterns/` matching work type

4. **Load Memory** — search `ai_team_config/memory_store/entities/` and `ai_team_config/memory_store/context/` for topic keywords

5. **Output:**
   ```
   ## Context for: {work-type}

   ### ADRs
   - **{ID}**: {one-line decision}

   ### Patterns
   - **{name}**: {summary}

   ### Memory
   - **{entity/context}**: {relevant notes}

   ### Checklist
   - [ ] {applicable checklist items}
   ```

## Token Budget

Target: <2000 tokens per invocation
- Index scan: ~200 tokens
- ADR summaries: ~150 each (450 max)
- Pattern loads: ~300 each (1200 max)
