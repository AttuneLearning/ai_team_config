---
name: testing-bugfix
parent_adr: DEV-001
status: active
work_types: [bug-fix]
created: 2026-02-04
usage_count: 0
---

# testing-bugfix

Regression test pattern for bug fixes.

## When
Before fixing any reported bug.

## Steps
1. Write failing test that reproduces the bug
2. Verify test fails (confirms bug exists)
3. Implement fix
4. Verify test passes
5. Run related tests to ensure no regressions

## Template

```typescript
describe('{Feature} - Bug Fix', () => {
  describe('regression: {bug-description}', () => {
    it('should {expected-behavior} (was: {bug-behavior})', async () => {
      // Setup: Create conditions that trigger the bug

      // Action: Perform the operation that was buggy

      // Assert: Verify correct behavior
    });
  });
});
```

## Example

```typescript
describe('Module API - Bug Fix', () => {
  describe('regression: ownerDepartmentId validation', () => {
    it('should require ownerDepartmentId on create (was: allowing null)', async () => {
      const res = await request(app)
        .post('/modules')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Test Module',
          // Missing ownerDepartmentId
        });

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('ownerDepartmentId');
    });
  });
});
```

## Checklist
- [ ] Test written BEFORE fix
- [ ] Test fails without fix
- [ ] Test passes with fix
- [ ] Related tests still pass
- [ ] No regressions introduced
