---
name: reflect
trigger: /reflect
description: Capture learnings after implementation phase
auto_trigger: false
---

# Reflect Skill

Post-implementation reflection to capture patterns and learnings.

## Usage

```
/reflect                    # Reflect on current session
/reflect API-ISS-014        # Reflect on specific issue
```

## Execution Steps

1. **Gather Context**
   - Review files modified in session
   - Check git diff for changes
   - Identify patterns used

2. **Analysis Questions**
   Ask internally (don't prompt user):
   - What patterns were followed?
   - What patterns were created or modified?
   - Were any ADRs violated? Why?
   - What would make this easier next time?

3. **Pattern Detection**
   Look for:
   - Repeated code structures (3+ occurrences)
   - Novel solutions to common problems
   - Workarounds that should be standardized
   - Anti-patterns that emerged

4. **Output Actions**

   **If new pattern detected:**
   ```
   ## New Pattern Detected

   **Name:** {suggested-name}
   **Type:** {work-type}
   **Summary:** {one-line}

   ### Code Example
   ```{language}
   {example}
   ```

   **Action:** Create draft pattern? [Yes] [No]
   ```

   **If ADR gap detected:**
   ```
   ## ADR Gap Detected

   **Domain:** {domain}
   **Issue:** {description}
   **Suggestion:** {what ADR should cover}

   **Action:** Create ADR suggestion? [Yes] [No]
   ```

   **If clean implementation:**
   ```
   ## Reflection Complete

   Patterns followed: {list}
   ADRs applied: {list}
   No new patterns or gaps detected.
   ```

5. **Auto-Actions**
   - Increment `usage_count` on patterns used
   - Flag patterns with 5+ uses for promotion review

## Pattern Promotion Criteria

Auto-promote when:
- usage_count >= 5
- No violations in last 3 uses
- Clear, non-controversial

Request approval when:
- usage_count >= 3 but <5
- Has been modified since creation
- Touches multiple domains
