---
name: validation-joi
parent_adr: API-001
status: active
work_types: [new-endpoint, new-model]
created: 2026-02-04
usage_count: 0
---

# validation-joi

Request validation pattern using Joi.

## When
Creating validators for new endpoints.

## Structure
Location: `src/validators/{feature}.validator.ts`

## Template

```typescript
import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';
import { ApiError } from '@/utils/ApiError';

// Reusable schemas
const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const objectIdSchema = Joi.string().pattern(objectIdPattern).messages({
  'string.pattern.base': '{{#label}} must be a valid ObjectId'
});

// Create schema
const createSchema = Joi.object({
  name: Joi.string().required().max(200).messages({
    'string.empty': 'Name is required',
    'string.max': 'Name cannot exceed 200 characters'
  }),
  description: Joi.string().max(2000).allow(null, ''),
  departmentId: objectIdSchema.required(),
  isActive: Joi.boolean().default(true)
});

// Update schema (all optional)
const updateSchema = Joi.object({
  name: Joi.string().max(200),
  description: Joi.string().max(2000).allow(null),
  isActive: Joi.boolean()
}).min(1).messages({
  'object.min': 'At least one field must be provided'
});

// List query schema
const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sort: Joi.string().pattern(/^-?(createdAt|updatedAt|name)$/),
  search: Joi.string().max(100)
});

// Validator middleware factory
const validate = (schema: Joi.Schema, source: 'body' | 'query' | 'params' = 'body') => {
  return (req: Request, _res: Response, next: NextFunction) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      const message = error.details.map(d => d.message).join(', ');
      return next(new ApiError(422, message));
    }

    req[source] = value;
    next();
  };
};

// Exports
export const validateCreate = validate(createSchema, 'body');
export const validateUpdate = validate(updateSchema, 'body');
export const validateList = validate(listQuerySchema, 'query');
export const validateId = validate(
  Joi.object({ id: objectIdSchema.required() }),
  'params'
);
```

## Common Patterns

```typescript
// Enum validation
type: Joi.string().valid('option1', 'option2', 'option3').required()

// Nested object
settings: Joi.object({
  enabled: Joi.boolean(),
  value: Joi.number().min(0).max(100)
})

// Array of ObjectIds
instructorIds: Joi.array().items(objectIdSchema).default([])

// Conditional required
endDate: Joi.date().when('hasEndDate', {
  is: true,
  then: Joi.required()
})

// Custom validation
code: Joi.string().uppercase().pattern(/^[A-Z0-9-]+$/).custom((value, helpers) => {
  if (reservedCodes.includes(value)) {
    return helpers.error('string.reserved');
  }
  return value;
}).messages({
  'string.reserved': 'This code is reserved'
})
```
