# Team Definitions (Codex)

This directory contains team definitions translated from `./.claude-workflow/teams/` plus Codex-specific installer profiles.

## Files

- `catalog.yaml`: generic role catalog (frontend, backend, mobile, cloud, data-warehousing, qa, platform)
- `protocol.yaml`: universal cross-team communication rules
- `profiles.json`: installer-ready team profiles (aliases, issue prefixes, default paths, enabled skills)

## Source of truth

- Keep role semantics aligned with `.claude-workflow/teams/catalog.yaml`
- Keep protocol semantics aligned with `.claude-workflow/teams/protocol.yaml`
- Use `profiles.json` for Codex runtime/install behavior

