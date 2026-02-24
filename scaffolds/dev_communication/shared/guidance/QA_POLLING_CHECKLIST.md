# QA Polling Checklist

Use this checklist after polling for new QA-ready work.

## Scope

- Applies to `Frontend-QA` and `Backend-QA`
- Canonical source: `ai_team_config/teams/checklists/qa-gate.yaml`
- Runner script: `ai_team_config/scripts/qa_poll_cycle.sh`

## Cycle

1. Poll inbox + active issues for `Development Complete` or `Awaiting QA`.
2. Confirm issue is in `issues/active/` with `Status: ACTIVE`.
3. Validate test coverage evidence and record missing tests/recommendations.
4. Run automated gates:
   - Typecheck
   - Unit tests
   - Integration tests
   - UAT tests
5. Perform manual review:
   - Efficiency
   - Accuracy
   - Non-duplication
   - Security
   - ADR conformance
6. Record verdict and evidence in the issue:
   - `Pass` / `Pass with Conditions` / `Blocked` / `Need More Info`
   - Include explicit unblock criteria when blocked
7. If pass, QA moves issue to `completed/` and sets `Status: COMPLETE`.
8. Move processed handoff message from inbox:
   - Preferred: `dev_communication/{team}/inbox/completed/`
   - Fallback: `dev_communication/archive/`

## Standard Commands

One-shot cycle:

```bash
ai_team_config/scripts/qa_poll_cycle.sh --once
```

Approve passing issues (after manual review):

```bash
ai_team_config/scripts/qa_poll_cycle.sh --once --manual-ok --approve
```

4-minute polling loop:

```bash
ai_team_config/scripts/qa_poll_cycle.sh --watch --interval 240
```
