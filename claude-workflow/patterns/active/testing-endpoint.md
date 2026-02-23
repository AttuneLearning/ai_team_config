---
name: testing-endpoint
parent_adr: DEV-001
status: active
work_types: [new-endpoint, new-feature]
created: 2026-02-04
usage_count: 0
---

# testing-endpoint

Integration test pattern for new API endpoints.

## When
After implementing: route + controller + service + validator

## Steps
1. Create `tests/integration/{feature}/{feature}.test.ts`
2. Use `describeIfMongo` wrapper
3. Setup: MongoMemoryServer, seed data, auth tokens
4. Test cases: happy-path, validation-error, not-found, unauthorized

## Template

```typescript
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import app from '@/app';
import { describeIfMongo } from '../../helpers/mongo-guard';

describeIfMongo('{Feature} API', () => {
  let mongoServer: MongoMemoryServer;
  let authToken: string;
  let testData: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());
    // Seed lookup values, roles, etc.
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    // Seed test data
    // Generate auth token
  });

  afterEach(async () => {
    // Clean collections
  });

  describe('GET /{resource}', () => {
    it('returns 200 with list', async () => {
      const res = await request(app)
        .get('/{resource}')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('returns 401 without auth', async () => {
      const res = await request(app).get('/{resource}');
      expect(res.status).toBe(401);
    });
  });

  describe('GET /{resource}/:id', () => {
    it('returns 200 for valid id', async () => {
      const res = await request(app)
        .get(`/{resource}/${testData.id}`)
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(200);
    });

    it('returns 404 for non-existent', async () => {
      const res = await request(app)
        .get('/{resource}/000000000000000000000000')
        .set('Authorization', `Bearer ${authToken}`);
      expect(res.status).toBe(404);
    });
  });

  describe('POST /{resource}', () => {
    it('returns 201 with valid data', async () => {
      const res = await request(app)
        .post('/{resource}')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ /* valid data */ });
      expect(res.status).toBe(201);
    });

    it('returns 422 for invalid data', async () => {
      const res = await request(app)
        .post('/{resource}')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ /* invalid data */ });
      expect(res.status).toBe(422);
    });
  });
});
```

## Lessons
- 2026-02-04: Skipping tests caused 308 failures when Module schema changed (ownerDepartmentId)
- Always test schema-dependent code paths
