---
id: task-010
title: Add hierarchy to notes
status: Done
assignee:
  - '@claude'
created_date: '2025-09-19 10:22'
updated_date: '2025-09-19 10:29'
labels:
  - backend
  - database
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Modify the Note model and database to support parent-child relationships for hierarchical note structures, enabling nested notes and better organization
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create database migration adding nullable parent_id to notes table
- [x] #2 Update Note model to include parent_id field and associations
- [x] #3 Update NoteCreateParams and NoteUpdateParams to accept parent_id
- [x] #4 Add validation to prevent circular references and self-referencing
- [x] #5 Update note controller tests to verify parent_id functionality
- [x] #6 Update swagger documentation to include parent_id field
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Analyze current Note schema structure and relationships
2. Create database migration to add parent_id field to notes table
3. Update Note schema to include parent_id field and self-referential associations
4. Update Note.changeset/4 to accept and validate parent_id parameter
5. Update Swagger schemas to include parent_id in NoteCreateParams and NoteUpdateParams
6. Update note controller tests to verify parent_id functionality
7. Run tests to ensure all existing functionality remains intact
8. Update swagger documentation generation
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented hierarchical note structure with parent-child relationships.

## Changes Made:

### Database
- Added migration to add nullable `parent_id` field to notes table with foreign key constraint and index
- Migration uses `on_delete: :nilify_all` to handle parent note deletion gracefully

### Note Model
- Added `parent_id` field to Note schema
- Added `belongs_to :parent` association for parent note
- Added `has_many :children` association for child notes
- Enhanced changeset validation with comprehensive parent_id validation:
  - Prevents self-referencing (note cannot be its own parent)
  - Validates parent note exists and belongs to same game
  - Prevents circular references using recursive cycle detection

### API
- Updated Swagger schemas to include parent_id in NoteCreateParams, NoteUpdateParams, and Note response
- Updated JSON response helper to include parent_id field in note data
- All existing API endpoints now support parent_id parameter

### Testing
- Added comprehensive test coverage for parent_id functionality:
  - Creating notes with valid parent_id
  - Updating notes with parent_id
  - Validation error scenarios (invalid parent, cross-game parent, self-reference, circular reference)
  - All existing tests continue to pass

## Technical Details:
- Uses binary_id for consistency with existing schema
- Implements robust validation to maintain data integrity
- Maintains backward compatibility - existing notes have parent_id = null
- Supports unlimited nesting depth with circular reference protection
<!-- SECTION:NOTES:END -->
