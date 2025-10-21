---
id: task-001
title: Add hierarchy to quests
status: Done
assignee:
  - '@claude'
created_date: '2025-09-19 09:48'
updated_date: '2025-09-19 10:03'
labels:
  - backend
  - database
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Modify the Quest model and database to support parent-child relationships for hierarchical quest structures
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create database migration adding nullable parent_id to quests table
- [x] #2 Update Quest model to include parent_id field
- [x] #3 Update QuestCreateParams and QuestUpdateParams to accept parent_id
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Analyze current Quest schema structure and relationships
2. Create database migration to add parent_id field to quests table
3. Update Quest schema to include parent_id field and self-referential association
4. Update Quest.changeset/4 to accept and validate parent_id parameter
5. Update Swagger schemas to include parent_id in QuestCreateParams and QuestUpdateParams
6. Update quest controller tests to verify parent_id functionality
7. Run tests to ensure all existing functionality remains intact
8. Update swagger documentation generation
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented hierarchical quest structure with parent-child relationships.

## Changes Made:

### Database
- Added migration to add nullable `parent_id` field to quests table with foreign key constraint and index
- Migration uses `on_delete: :nilify_all` to handle parent quest deletion gracefully

### Quest Model
- Added `parent_id` field to Quest schema
- Added `belongs_to :parent` association for parent quest
- Added `has_many :children` association for child quests
- Enhanced changeset validation with comprehensive parent_id validation:
  - Prevents self-referencing (quest cannot be its own parent)
  - Validates parent quest exists and belongs to same game
  - Prevents circular references using recursive cycle detection

### API
- Updated Swagger schemas to include parent_id in QuestCreateParams, QuestUpdateParams, and Quest response
- Updated JSON response helper to include parent_id field in quest data
- All existing API endpoints now support parent_id parameter

### Testing
- Added comprehensive test coverage for parent_id functionality:
  - Creating quests with valid parent_id
  - Updating quests with parent_id
  - Validation error scenarios (invalid parent, cross-game parent, self-reference, circular reference)
  - All existing tests continue to pass

## Technical Details:
- Uses binary_id for consistency with existing schema
- Implements robust validation to maintain data integrity
- Maintains backward compatibility - existing quests have parent_id = null
- Supports unlimited nesting depth with circular reference protection
<!-- SECTION:NOTES:END -->
