# ADR Index
<!-- Token-optimized. Scan first, load full ADR only when relevant. -->

## Format
ID|Domain|Decision|Keywords|Patterns

## Index
DEV-001|Testing|LazyTDD:tests-after-impl|T1,T2,T3,jest,integration,unit|testing-*
DEV-002|Design|IdealFirst:no-backward-compat|clean,no-deprecated,no-shim,refactor|—
API-001|Endpoints|REST:conventions|naming,versioning,v2,routes,controller|endpoint-*,validation-*
API-002|Caching|Strategy:redis-optional|cache,redis,memory,ttl|—
API-003|REST|ResponseFormat:standard|ApiResponse,pagination,errors,success|response-*
DATA-001|Models|Mongoose:conventions|schema,timestamps,softdelete,index|model-*
AUTH-001|Auth|UnifiedModel:scoped-perms|authorize,accessRight,department,role|auth-*
SEC-001|Security|Standards:owasp|xss,injection,validation,sanitize|validation-*
VERS-001|Versioning|CourseVersioning:immutable|CanonicalCourse,CourseVersion,publish,draft|versioning-*

## Quick Reference

### Testing (DEV-001)
- T1: Tests after each phase/issue
- T2: Full suite at milestone
- T3: `tsc --noEmit` before complete

### Design (DEV-002)
- No backward compatibility unless explicit
- No deprecated fields or shims
- Ideal structure over compatibility

### Auth (AUTH-001)
- Format: `domain:resource:action`
- Examples: `content:courses:read`, `admin:users:manage`
- Use `authorize()` middleware

## ADR Locations
Path: `dev_communication/shared/architecture/decisions/ADR-{ID}.md`
