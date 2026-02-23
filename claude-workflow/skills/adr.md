---
name: adr
description: Manage architecture decisions, gaps, and suggestions
argument-hint: "[check|gaps|suggest|poll|create|review]"
---

# Architecture Decision Management

Manage ADRs, track gaps, and process suggestions.

## Actions

Based on arguments or user request, perform one of these actions:

---

### 1. STATUS (default - no arguments)

Show current architecture status.

**Trigger:** `/adr`, `/adr status`

**Steps:**
1. Read `dev_communication/shared/architecture/index.md`
2. Count files in `dev_communication/shared/architecture/suggestions/`
3. Read `dev_communication/shared/architecture/gaps/index.md` for gap count
4. Read `dev_communication/shared/architecture/decision-log.md` for ADR count

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
1. Read architecture index: `dev_communication/shared/architecture/index.md`
2. Read decision log: `dev_communication/shared/architecture/decision-log.md`
3. Scan all ADRs in: `dev_communication/shared/architecture/decisions/*.md`
4. For each ADR extract: ID, Title, Status, Domain
5. Compare against expected architecture areas
6. Read `dev_communication/shared/architecture/gaps/index.md`
7. Generate comprehensive report

---

### 3. GAPS - Gap Analysis Only

**Trigger:** `/adr gaps`

**Steps:**
1. Read `dev_communication/shared/architecture/gaps/index.md`
2. For each gap, summarize: Domain, Priority, Suggested ADR
3. Recommend top 3 to address

---

### 4. SUGGEST - Create Architecture Suggestion

**Trigger:** `/adr suggest`, `/adr suggest [topic]`

**Steps:**
1. If no topic, ask for: Topic, Context, Teams affected, Priority
2. Generate filename: `YYYY-MM-DD_{team}_{topic_slug}.md`
3. Create in `dev_communication/shared/architecture/suggestions/`
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
3. Read template from `dev_communication/shared/architecture/templates/adr-template.md`
4. Save to: `dev_communication/shared/architecture/decisions/ADR-{DOMAIN}-{NNN}-{TITLE}.md`
5. Update: `dev_communication/shared/architecture/decision-log.md`
6. Update: `dev_communication/shared/architecture/index.md`
7. If from suggestion, archive the suggestion
8. If gap addressed, update gaps index
9. Confirm created

---

### 7. REVIEW - Review/Update Existing ADR

**Trigger:** `/adr review [ADR-ID]`

**Steps:**
1. Read the ADR from `dev_communication/shared/architecture/decisions/`
2. Check for staleness, missing links, implementation drift
3. Suggest updates if needed
4. If user approves, update the ADR
5. Update decision log if status changed

---

## File Locations

```
dev_communication/shared/architecture/
├── index.md              # Main hub
├── decision-log.md       # Chronological ADR list
├── decisions/            # ADR files
├── templates/            # ADR template
├── suggestions/          # Pending suggestions
└── gaps/                 # Gap tracker
```
