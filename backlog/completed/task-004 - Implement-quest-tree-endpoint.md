---
id: task-004
title: Implement quest tree endpoint
status: Done
assignee:
  - '@claude'
created_date: '2025-09-19 09:48'
updated_date: '2025-09-19 15:59'
labels:
  - backend
  - api
dependencies: []
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build GET .../quests/tree endpoint to provide hierarchical quest data for the World Outline panel
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create endpoint route for GET .../quests/tree
- [x] #2 Implement service logic to build quest hierarchy using parent_id relationships
- [x] #3 Return properly structured tree data with parent-child relationships
- [x] #4 Add endpoint tests and validation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Research and understand existing codebase structure
   - Quest schema with parent_id self-reference ✓
   - Existing Quests context module with list functions ✓
   - QuestController with CRUD operations ✓
   - Quest schema has content field instead of description ✓
   - Similar structure to locations with game scoping ✓

2. Add tree function to Quests context
   - Create list_quests_tree_for_game/1 function
   - Build hierarchical structure from parent-child relationships
   - Handle proper scoping (game-specific)
   - Optimize query with proper preloading
   - Use same algorithm pattern as locations

3. Add tree endpoint to QuestController
   - Add tree/2 action function
   - Route: GET /api/games/:game_id/quests/tree
   - Use existing current_scope authentication
   - Return JSON tree structure

4. Update router configuration
   - Add tree route to quests (outside resources block)
   - Follow pattern from locations: GET /quests/tree before resources

5. Add Swagger documentation
   - Update QuestSwagger module
   - Document tree endpoint schema and response
   - Create QuestTreeNode and QuestTreeResponse schemas
   - Follow existing swagger patterns

6. Create comprehensive tests
   - Controller tests for tree endpoint (8 tests)
   - Context tests for tree building logic (8 tests)
   - Test edge cases (empty tree, single level, deep nesting)
   - Test authentication and authorization
   - Follow existing test patterns from locations

7. Validate and test complete implementation
   - Run existing test suite
   - Test tree endpoint manually
   - Verify proper JSON structure
   - Check performance with sample data
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully implemented quest tree endpoint with comprehensive functionality:

## Implementation Summary
- Added `list_quests_tree_for_game/1` function to Quests context
- Built efficient tree-building algorithm using Enum.group_by for O(n) performance
- Added tree/2 controller action with proper authentication/authorization
- Added tree/1 JSON renderer for consistent API response format
- Updated router with GET /quests/tree route (placed before resources to avoid conflicts)
- Added complete Swagger documentation with QuestTreeNode and QuestTreeResponse schemas
- Created comprehensive test coverage:
  - 8 controller integration tests covering all scenarios
  - 8 context unit tests for tree building logic
  - Tests cover empty trees, flat structures, deep hierarchies, multiple children, field inclusion, game isolation, and access control

## Technical Approach
- Used hierarchical tree structure with recursive child building
- Implemented proper game-scoped queries for security
- Maintained alphabetical sorting at each level
- Preserved all quest fields (id, name, content, content_plain_text, tags, parent_id)
- Added children array to each node for frontend consumption
- Followed same proven pattern as location tree implementation

## API Endpoint
GET /api/games/{game_id}/quests/tree
- Returns JSON array of root quest nodes
- Each node contains full quest data plus children array
- Supports deep nesting and proper parent-child relationships
- Authenticated via existing current_scope mechanism

All tests passing (104/104) with no warnings or errors.
<!-- SECTION:NOTES:END -->
