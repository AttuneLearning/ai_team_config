---
name: refine
trigger: /refine
description: Review and refine patterns, promote to ADRs
auto_trigger: false
---

# Refine Skill

Periodic review and refinement of patterns and ADRs.

## Usage

```
/refine                     # Full refinement cycle
/refine patterns            # Review patterns only
/refine promote             # Review promotion candidates
/refine {pattern-name}      # Refine specific pattern
```

## Execution Steps

### Full Refinement (`/refine`)

1. **Pattern Health Check**
   - List patterns by usage_count (desc)
   - Flag stale patterns (0 uses in 30 days)
   - Flag conflicting patterns

2. **Promotion Review**
   - List patterns with usage_count >= 5
   - For each, assess promotion readiness:
     - Is it decision-worthy? (affects architecture)
     - Is it stable? (no recent changes)
     - Is it universal? (applies beyond one feature)

3. **Gap Analysis**
   - Cross-reference work-type-index coverage
   - Identify work types with <2 patterns
   - Suggest patterns to create

4. **Output**
   ```
   ## Refinement Report

   ### Promotion Candidates
   | Pattern | Uses | Recommendation |
   |---------|------|----------------|
   | {name}  | {n}  | Promote / Keep / Review |

   ### Stale Patterns
   - {name}: Last used {date}, consider archiving

   ### Coverage Gaps
   - {work-type}: Only {n} patterns, consider adding {suggestions}

   ### Actions Available
   1. Promote {pattern} to ADR
   2. Archive {pattern}
   3. Create pattern for {gap}
   ```

### Pattern Promotion (`/refine promote {pattern}`)

1. **Extract ADR Content**
   - Title: Pattern name → ADR title
   - Decision: Pattern summary → Decision statement
   - Context: Why pattern was created
   - Consequences: What using this pattern means

2. **Create ADR Draft**
   - Generate ADR-{DOMAIN}-{NNN} ID
   - Use lean ADR format
   - Link back to pattern for code examples

3. **Update Pattern**
   - Change status: active → promoted
   - Add `promoted_to: ADR-XXX-NNN`
   - Keep pattern for code examples

### Pattern Archive (`/refine archive {pattern}`)

1. Move from `patterns/active/` to `patterns/archived/`
2. Update indexes
3. Log reason in pattern frontmatter

## Refinement Schedule

Recommended triggers:
- After every 10-15 implementation phases
- Before major releases
- When adding new team members
- Quarterly review minimum
