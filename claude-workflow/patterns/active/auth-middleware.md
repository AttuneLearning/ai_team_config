---
name: auth-middleware
parent_adr: AUTH-001
status: active
work_types: [auth-change, new-endpoint]
created: 2026-02-04
usage_count: 0
---

# auth-middleware

Authentication and authorization middleware patterns.

## When
Adding auth to new endpoints or modifying auth logic.

## Middleware Chain

```typescript
router.use(isAuthenticated);  // First: verify JWT
router.get('/', authorize('content:courses:read'), controller.list);  // Then: check permission
```

## Access Right Format

```
domain:resource:action
```

### Domains
- `content` - Course, module, learning content
- `admin` - System administration
- `reports` - Analytics and reporting
- `grades` - Grading and assessments
- `learner` - Learner data access

### Actions
- `read` - View/list
- `manage` - Create/update/delete
- `*` - All actions

### Examples

```typescript
// Content permissions
authorize('content:courses:read')      // View courses
authorize('content:courses:manage')    // Create/edit courses
authorize('content:certificates:read') // View certificates
authorize('content:certificates:manage') // Issue certificates

// Admin permissions
authorize('admin:users:manage')        // Manage users
authorize('admin:departments:read')    // View departments

// Reports
authorize('reports:department:read')   // Department reports

// Own data
authorize('grades:own:read')           // Learner's own grades
authorize('learner:pii:read')          // Learner PII access
```

## Multiple Permissions (Any Of)

```typescript
router.get('/',
  authorize.anyOf(['reports:department:read', 'admin:reports:read']),
  controller.list
);
```

## Department Scoping

```typescript
// In controller/service
const departmentId = (req as any).user.departmentId;
// Use departmentId to scope queries
```

## Common Patterns

```typescript
// Public endpoint (no auth)
router.get('/public/verify/:code', controller.verify);

// Auth required, no specific permission
router.use(isAuthenticated);
router.get('/me', controller.getCurrentUser);

// Auth + specific permission
router.post('/',
  isAuthenticated,
  authorize('content:courses:manage'),
  validateCreate,
  controller.create
);

// Nested resource with parent check
router.get('/:parentId/children',
  isAuthenticated,
  authorize('content:courses:read'),
  // Service checks user has access to parent
  controller.listChildren
);
```

## User Object in Request

```typescript
// After isAuthenticated, req.user contains:
interface AuthUser {
  userId: string;
  email: string;
  departmentId: string;
  roles: string[];
  accessRights: string[];
}

// Access in controller
const userId = (req as any).user.userId;
const departmentId = (req as any).user.departmentId;
```

## Checklist
- [ ] Access right follows `domain:resource:action` format
- [ ] Access right exists in system (check AccessRight model)
- [ ] isAuthenticated applied before authorize
- [ ] Public endpoints explicitly skip auth
- [ ] Department scoping applied where needed
