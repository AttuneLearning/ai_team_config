---
name: endpoint-structure
parent_adr: API-001
status: active
work_types: [new-endpoint]
created: 2026-02-04
usage_count: 0
---

# endpoint-structure

Standard structure for new API endpoints.

## When
Creating new routes/controllers/services.

## File Structure

```
src/
├── routes/v2/{feature}.routes.ts       # Route definitions
├── controllers/{domain}/{feature}.controller.ts
├── services/{domain}/{feature}.service.ts
├── validators/{feature}.validator.ts
└── models/{domain}/{Entity}.model.ts
```

## Route Pattern

```typescript
// src/routes/v2/{feature}.routes.ts
import { Router } from 'express';
import { isAuthenticated } from '@/middlewares/isAuthenticated';
import { authorize } from '@/middlewares/authorize';
import { validateCreate, validateUpdate, validateList } from '@/validators/{feature}.validator';
import * as controller from '@/controllers/{domain}/{feature}.controller';

const router = Router();

// Apply auth to all routes
router.use(isAuthenticated);

// List
router.get('/', authorize('content:{resource}:read'), validateList, controller.list);

// Get by ID
router.get('/:id', authorize('content:{resource}:read'), controller.getById);

// Create
router.post('/', authorize('content:{resource}:manage'), validateCreate, controller.create);

// Update
router.patch('/:id', authorize('content:{resource}:manage'), validateUpdate, controller.update);

// Delete
router.delete('/:id', authorize('content:{resource}:manage'), controller.remove);

export default router;
```

## Controller Pattern

```typescript
// src/controllers/{domain}/{feature}.controller.ts
import { Request, Response } from 'express';
import { {Feature}Service } from '@/services/{domain}/{feature}.service';
import { ApiResponse } from '@/utils/ApiResponse';
import { asyncHandler } from '@/utils/asyncHandler';

export const list = asyncHandler(async (req: Request, res: Response) => {
  const result = await {Feature}Service.list(req.query);
  res.json(ApiResponse.success(result));
});

export const getById = asyncHandler(async (req: Request, res: Response) => {
  const result = await {Feature}Service.getById(req.params.id);
  res.json(ApiResponse.success(result));
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const userId = (req as any).user.userId;
  const result = await {Feature}Service.create(req.body, userId);
  res.status(201).json(ApiResponse.success(result, '{Feature} created'));
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const result = await {Feature}Service.update(req.params.id, req.body);
  res.json(ApiResponse.success(result, '{Feature} updated'));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await {Feature}Service.delete(req.params.id);
  res.json(ApiResponse.success(null, '{Feature} deleted'));
});
```

## Service Pattern

```typescript
// src/services/{domain}/{feature}.service.ts
import mongoose from 'mongoose';
import {Entity} from '@/models/{domain}/{Entity}.model';
import { ApiError } from '@/utils/ApiError';

export class {Feature}Service {
  static async list(filters: any) {
    const { page = 1, limit = 20, sort = '-createdAt', ...query } = filters;

    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      {Entity}.find(query).sort(sort).skip(skip).limit(limit).lean(),
      {Entity}.countDocuments(query)
    ]);

    return {
      items,
      pagination: {
        page, limit, total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1
      }
    };
  }

  static async getById(id: string) {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid ID');
    }
    const item = await {Entity}.findById(id);
    if (!item) throw ApiError.notFound('{Entity} not found');
    return item;
  }

  static async create(data: any, userId: string) {
    const item = new {Entity}({ ...data, createdBy: userId });
    await item.save();
    return item;
  }

  static async update(id: string, data: any) {
    const item = await {Entity}.findByIdAndUpdate(id, data, { new: true });
    if (!item) throw ApiError.notFound('{Entity} not found');
    return item;
  }

  static async delete(id: string) {
    const item = await {Entity}.findByIdAndUpdate(id, { isActive: false });
    if (!item) throw ApiError.notFound('{Entity} not found');
  }
}
```

## Register in app.ts

```typescript
import {feature}Routes from './routes/{feature}.routes';
app.use('/{resource}', {feature}Routes);
```

## Checklist
- [ ] Route file created with auth middleware
- [ ] Controller uses asyncHandler
- [ ] Service handles validation and errors
- [ ] Validator created with Joi schemas
- [ ] Route registered in app.ts
- [ ] Access rights use correct format: `domain:resource:action`
