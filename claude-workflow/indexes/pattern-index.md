# Pattern Index
<!-- Token-optimized. Scan first, load full pattern only when implementing. -->

## Format
ID|WorkTypes|ParentADR|Status|Summary

## Active Patterns
testing-endpoint|new-endpoint,new-feature|DEV-001|active|describeIfMongo,supertest,beforeAll/afterAll,happy+error+auth
testing-bugfix|bug-fix|DEV-001|active|regression-first,reproduce,fix,verify-green
testing-uat-playwright|new-feature,new-page,user-story|DEV-001|active|Playwright,PageObjects,fixtures,Given/When/Then,data-testid
validation-joi|new-endpoint,new-model|API-001|active|Joi.object,required,pattern,messages,asyncHandler
model-mongoose|new-model|DATA-001|active|Schema,timestamps:true,indexes,virtuals,methods
endpoint-structure|new-endpoint|API-001|active|route→isAuthenticated→authorize→validate→controller→service
auth-middleware|auth-change,new-endpoint|AUTH-001|active|isAuthenticated,authorize('domain:resource:action')

## Draft Patterns
<!-- New patterns being validated. Move to active after 3+ successful uses. -->

## Promoted Patterns
<!-- Graduated to ADR. Kept for reference. -->

## Pattern Locations
- Shared: `.claude-workflow/patterns/{status}/`
- Project: `memory/patterns/{status}/`
