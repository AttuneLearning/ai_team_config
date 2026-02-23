# Work Type Index
<!-- Maps task types to relevant ADRs and patterns. -->

## Work Types

| Type | ADRs | Patterns | Pre-Check |
|------|------|----------|-----------|
| new-endpoint | DEV-001,API-001,AUTH-001 | testing-endpoint,validation-joi,endpoint-structure,auth-middleware | Auth right exists? |
| new-model | DEV-001,DATA-001 | testing-endpoint,model-mongoose,validation-joi | Schema reviewed? |
| new-feature | DEV-001,DEV-002,API-001 | testing-endpoint,validation-joi,endpoint-structure | Contract defined? |
| bug-fix | DEV-001 | testing-bugfix | Repro steps clear? |
| refactor | DEV-002 | — | Tests passing first? |
| auth-change | AUTH-001,SEC-001 | auth-middleware,validation-joi | Security reviewed? |
| versioning | VERS-001,DEV-001 | testing-endpoint | Migration planned? |
| cross-team | DEV-001,API-001 | — | Contract sent? |

## Auto-Detection Keywords

```yaml
new-endpoint:
  - "create endpoint"
  - "add route"
  - "new route"
  - "POST /api"
  - "GET /api"
  - "PATCH /api"
  - "DELETE /api"
  - "implement endpoint"

new-model:
  - "create model"
  - "new model"
  - "add schema"
  - "new schema"
  - "add collection"
  - "mongoose model"

new-feature:
  - "implement feature"
  - "add feature"
  - "new feature"
  - "build feature"
  - "create system"
  - "implement system"
  - "API-ISS-"

bug-fix:
  - "fix bug"
  - "fix issue"
  - "resolve bug"
  - "broken"
  - "not working"
  - "failing"
  - "error in"

refactor:
  - "refactor"
  - "restructure"
  - "clean up"
  - "reorganize"
  - "simplify"

auth-change:
  - "permission"
  - "authorization"
  - "access right"
  - "role"
  - "authenticate"
  - "authorize"

versioning:
  - "version"
  - "CourseVersion"
  - "CanonicalCourse"
  - "publish"
  - "draft version"

cross-team:
  - "UI team"
  - "API team"
  - "contract"
  - "cross-team"
  - "/comms"
```

## Default
If no keywords match: `new-feature` (most comprehensive coverage)
