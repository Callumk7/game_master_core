---
id: task-016
title: Implement faction note tree endpoint
status: Done
assignee:
  - '@claude'
created_date: '2025-09-20 15:21'
updated_date: '2025-10-02 14:38'
labels: []
dependencies: []
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build /tree endpoint for Factions to fetch hierarchical child note structures using the new polymorphic parent relationships. This enables frontend components to display note trees attached to specific factions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create faction note tree function in Notes context
- [x] #2 Add tree endpoint to FactionController for GET .../factions/:id/notes/tree
- [x] #3 Update router configuration for faction tree route
- [x] #4 Add Swagger documentation for faction note tree endpoint
- [x] #5 Create comprehensive tests for faction tree endpoint and context function
- [x] #6 Ensure proper authentication and game scoping
- [x] #7 Support both polymorphic parents (with parent_type) and traditional note hierarchies
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add list_faction_notes_tree_for_game/2 function to Notes context
2. Add notes_tree/2 action to FactionController with proper authentication and parameter handling
3. Add notes_tree/1 function to FactionJSON for response rendering
4. Update router.ex to include faction notes tree route
5. Add Swagger documentation with FactionNotesTreeData schema
6. Create comprehensive tests for both Notes context function and FactionController endpoint
7. Run tests and ensure swagger generation works
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully implemented faction note tree endpoint with full functionality:

## What was implemented:
- Created list_faction_notes_tree_for_game/2 function in Notes context that builds hierarchical note structures for factions using polymorphic parent relationships
- Added notes_tree/2 action to FactionController handling GET /api/games/:game_id/factions/:faction_id/notes/tree
- Added notes_tree/1 function to FactionJSON for response rendering
- Updated router.ex to include the new nested route under factions resources
- Added comprehensive Swagger documentation with FactionNotesTreeData and FactionNotesTreeResponse schemas
- Created full test suite covering normal cases, edge cases, authentication, and permissions

## Technical decisions:
- Used flexible parameter handling (faction_id = params["faction_id"] || params["id"]) to support both nested route parameter styles
- Implemented proper game scoping and authentication following existing patterns from character implementation
- Reused existing NoteTreeNode schema from character implementation for consistency
- Used the same build_entity_note_tree helper function that character implementation uses for consistency

## Files modified:
- lib/game_master_core/notes.ex - Added list_faction_notes_tree_for_game/2
- lib/game_master_core_web/controllers/faction_controller.ex - Added notes_tree action and Notes alias
- lib/game_master_core_web/controllers/faction_json.ex - Added notes_tree response and note_tree_data helper
- lib/game_master_core_web/router.ex - Added faction notes tree route
- lib/game_master_core_web/swagger_definitions.ex - Added FactionNotesTreeData schema and response
- lib/game_master_core_web/swagger/faction_swagger.ex - Added notes_tree swagger path
- test files - Comprehensive test coverage for all functionality

All tests pass and swagger generation works correctly.
<!-- SECTION:NOTES:END -->
