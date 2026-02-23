---
name: model-mongoose
parent_adr: DATA-001
status: active
work_types: [new-model]
created: 2026-02-04
usage_count: 0
---

# model-mongoose

Mongoose model pattern for new database schemas.

## When
Creating new MongoDB collections.

## Structure
Location: `src/models/{domain}/{Entity}.model.ts`

## Template

```typescript
import mongoose, { Schema, Document } from 'mongoose';

/**
 * Interface for {Entity}
 */
export interface I{Entity} extends Document {
  // Required fields
  name: string;
  departmentId: mongoose.Types.ObjectId;

  // Optional fields
  description?: string;

  // Status/flags
  isActive: boolean;

  // Timestamps (auto)
  createdAt: Date;
  updatedAt: Date;
}

const {Entity}Schema = new Schema<I{Entity}>(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      maxlength: [200, 'Name cannot exceed 200 characters'],
      trim: true
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      required: [true, 'Department ID is required'],
      index: true
    },
    description: {
      type: String,
      maxlength: [2000, 'Description cannot exceed 2000 characters'],
      default: null
    },
    isActive: {
      type: Boolean,
      default: true
    }
  },
  {
    timestamps: true  // Adds createdAt, updatedAt
  }
);

// Indexes
{Entity}Schema.index({ departmentId: 1, name: 1 });
{Entity}Schema.index({ departmentId: 1, createdAt: -1 });

// Soft delete index (if using isActive for soft delete)
{Entity}Schema.index({ departmentId: 1, isActive: 1 });

// Virtual for ID string
{Entity}Schema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Ensure virtuals in JSON
{Entity}Schema.set('toJSON', { virtuals: true });
{Entity}Schema.set('toObject', { virtuals: true });

const {Entity} = mongoose.model<I{Entity}>('{Entity}', {Entity}Schema);

export default {Entity};
```

## Common Patterns

```typescript
// Enum field
status: {
  type: String,
  enum: ['draft', 'active', 'archived'],
  default: 'draft'
}

// Reference with populate path
createdBy: {
  type: Schema.Types.ObjectId,
  ref: 'User',
  required: true
}

// Array of references
instructorIds: [{
  type: Schema.Types.ObjectId,
  ref: 'User'
}]

// Nested object
settings: {
  isPublic: { type: Boolean, default: false },
  maxAttempts: { type: Number, default: 3 }
}

// Map type
metadata: {
  type: Map,
  of: Schema.Types.Mixed,
  default: new Map()
}

// TTL index (auto-delete after expiry)
expiresAt: {
  type: Date,
  index: { expireAfterSeconds: 0 }
}

// Compound unique index
{Entity}Schema.index(
  { departmentId: 1, code: 1 },
  { unique: true }
);

// Text search index
{Entity}Schema.index(
  { name: 'text', description: 'text' },
  { weights: { name: 10, description: 5 } }
);
```

## Checklist
- [ ] Interface defined with all fields
- [ ] Required fields have validation messages
- [ ] Indexes for query patterns
- [ ] timestamps: true enabled
- [ ] Soft delete pattern if needed (isActive or isDeleted)
