---
name: adr
description: Manage architecture decisions, gaps, and suggestions
argument-hint: "[check|gaps|suggest|poll|create|review]"
---

# Architecture Decision Management

Manage ADRs, track gaps, and process suggestions.

## Configuration

Before performing any action below, **resolve the ADR root** once:

1. Look for `./.adr-config.yml` at the project root.
2. If present and it defines `adr_root`, use that value as `{adr_root}`.
3. Otherwise, default `{adr_root}` to `dev_communication/shared/architecture`.

Every `{adr_root}/…` path in the rest of this document refers to the resolved value. Substitute it before acting.

### Example `.adr-config.yml`

```yaml
# Override the ADR storage root.
# Default when this file is absent: dev_communication/shared/architecture
adr_root: docs/architecture
```

A project that uses the default layout does not need a config file. See `.adr-config.yml.example` at the submodule root for the canonical template.

## Actions

Based on arguments or user request, perform one of these actions:

---

### 1. STATUS (default - no arguments)

Show current architecture status.

**Trigger:** `/adr`, `/adr status`

**Steps:**
1. Read `{adr_root}/index.md`
2. Count files in `{adr_root}/suggestions/`
3. Read `{adr_root}/gaps/index.md` for gap count
4. Read `{adr_root}/decision-log.md` for ADR count

**Output:**
```
## Architecture Status

### ADRs: [count] documented
- [count] Accepted
- [count] Proposed

### Gaps: [count] known
- [count] High priority
- [count] Medium priority

### Suggestions: [count] pending review

Use `/adr check` for full analysis.
```

---

### 2. CHECK - Full Traversal & Analysis

**Trigger:** `/adr check`, `/adr check [domain]`

**Steps:**
1. Read architecture index: `{adr_root}/index.md`
2. Read decision log: `{adr_root}/decision-log.md`
3. Scan all ADRs in: `{adr_root}/decisions/*.md`
4. For each ADR extract: ID, Title, Status, Domain
5. Compare against expected architecture areas
6. Read `{adr_root}/gaps/index.md`
7. Generate comprehensive report

---

### 3. GAPS - Gap Analysis Only

**Trigger:** `/adr gaps`

**Steps:**
1. Read `{adr_root}/gaps/index.md`
2. For each gap, summarize: Domain, Priority, Suggested ADR
3. Recommend top 3 to address

---

### 4. SUGGEST - Create Architecture Suggestion

**Trigger:** `/adr suggest`, `/adr suggest [topic]`

**Steps:**
1. If no topic, ask for: Topic, Context, Teams affected, Priority
2. Generate filename: `YYYY-MM-DD_{team}_{topic_slug}.md`
3. Create in `{adr_root}/suggestions/`
4. Confirm created

---

### 5. POLL - Scan Messages/Issues for Architecture Decisions

**Trigger:** `/adr poll`

**Steps:**
1. Scan messaging directories for unprocessed messages
2. Scan active issues
3. Look for keywords: "architecture", "pattern", "design decision", "convention"
4. Report findings and suggest actions

---

### 6. CREATE - Create ADR

**Trigger:** `/adr create`, `/adr create [suggestion-file]`

**Steps:**
1. If suggestion file provided, use content to populate ADR
2. Otherwise ask for: Domain, Title, Context, Decision, Consequences
3. Read template from `{adr_root}/templates/adr-template.md`
4. Save to: `{adr_root}/decisions/ADR-{DOMAIN}-{NNN}-{TITLE}.md`
5. Update: `{adr_root}/decision-log.md`
6. Update: `{adr_root}/index.md`
7. If from suggestion, archive the suggestion
8. If gap addressed, update gaps index
9. Confirm created

---

### 7. REVIEW - Review/Update Existing ADR

**Trigger:** `/adr review [ADR-ID]`

**Steps:**
1. Read the ADR from `{adr_root}/decisions/`
2. Check for staleness, missing links, implementation drift
3. Suggest updates if needed
4. If user approves, update the ADR
5. Update decision log if status changed

---

## File Locations

```
{adr_root}/
├── index.md              # Main hub
├── decision-log.md       # Chronological ADR list
├── decisions/            # ADR files
├── templates/            # ADR template
├── suggestions/          # Pending suggestions
└── gaps/                 # Gap tracker
```
