# Session: API-ISS-079 Data Model Canonical Spec Alignment

**Date:** 2026-02-23
**Issue:** API-ISS-079
**Status:** COMPLETE

## Summary

Comprehensive alignment of all MongoDB models to the canonical spec (`docs/specs/API_CANONICAL_MODEL_SCHEMAS.md`). Five phases completed across 6 models, 3 contracts, 2 DTO mappers, 1 validator, and 3 test files.

## Changes by Phase

### Phase 1: Critical Schema Divergence (3 models)

**Module.model.ts:**
- `ICompletionCriteria.type`: `'all'|'percentage'|'specific'` → `'all_required'|'percentage'|'gate_learning_unit'|'points'`
- Added: `percentageRequired`, `pointsRequired`, `gateLearningUnitScore`, `requireAllExpositions`
- `IPresentationRules`: Replaced `{ sequential, allowSkipAhead }` with full 12-field spec (presentationMode, repetitionMode, repeatOn, etc.)
- Added top-level: `ownerDepartmentId`, `isShared`, `prerequisites`, `gateLearningUnitId`, `isPublished`, `availableFrom`, `availableUntil`, `estimatedDuration`, `objectives`

**LearningUnit.model.ts:**
- Added: `isRequired`, `isReplayable`, `weight`, `availableFrom`, `availableUntil`, `estimatedDuration`, `metadata`
- Added sub-docs: `IFlashcardSessionConfig`, `IGateConfig`, `IAdaptiveConfig`
- Settings: Added `allowMultipleAttempts`, `shuffleQuestions`

**Question.model.ts:**
- Added 6 type-specific sub-documents: `matchingData`, `trueFalseData`, `shortAnswerData`, `longAnswerData`, `fillBlankData`, `flashcardData`
- Added: `distractors`, `modelAnswer`, `maxWordCount`, `metadata`
- Changed `cognitiveDepth` from Number to String

### Phase 2: Data Quality (3 models)
- **Course.model.ts**: Added `code?: string`, `programId?: ObjectId`, sparse code index
- **LearnerCardState.model.ts**: Added `createdAt` to interface
- Exercise.model.ts: Already correct (uses `departmentId`)

### Phase 3: standardSchemaOptions (3 models)
- **ModuleEditLock.model.ts**: Added standardSchemaOptions
- **MatchingSession.model.ts**: Replaced `{ timestamps: true }` with standardSchemaOptions
- **MediaUploadRequest.model.ts**: Replaced `{ timestamps: true }` with standardSchemaOptions

### Phase 4: Audit Fields
- PlaylistSession.model.ts: Already uses `...auditFields`

### Phase 5: Indexes
- All added during their respective phases (Question departmentId+difficulty, LearningUnit moduleId+isActive+sequence, Course code sparse)

## Updated Files
- `src/models/curriculum/Module.model.ts`
- `src/models/curriculum/LearningUnit.model.ts`
- `src/models/curriculum/Course.model.ts`
- `src/models/curriculum/ModuleEditLock.model.ts`
- `src/models/content/Question.model.ts`
- `src/models/content/MatchingSession.model.ts`
- `src/models/content/MediaUploadRequest.model.ts`
- `src/models/flashcards/LearnerCardState.model.ts`
- `src/dto/curriculum/CurriculumDTOs.ts`
- `src/dto/content/ContentDTOs.ts`
- `src/validators/curriculum.validator.ts`
- `contracts/types/curriculum.ts`
- `contracts/types/content.ts`
- `tests/unit/models/curriculum/Module.model.test.ts`
- `tests/unit/models/curriculum/LearningUnit.model.test.ts`
- `tests/unit/models/content/Question.model.test.ts`

## Verification
- `npx tsc --noEmit`: 0 errors
- `npm run test:unit`: 663/663 tests passing (75 suites)

## Learnings
- Module's old `completionCriteria.type: 'all'` maps to new `'all_required'`
- Exercise model already used `departmentId` (issue description was stale)
- PlaylistSession already used `...auditFields` (issue description was stale)
- MediaAttachment already had standardSchemaOptions
