---
id: task-003
title: Implement location tree endpoint
status: Done
assignee:
  - '@claude'
created_date: '2025-09-19 09:48'
updated_date: '2025-09-19 15:44'
labels:
  - backend
  - api
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build GET .../locations/tree endpoint to provide hierarchical location data for the World Outline panel
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create endpoint route for GET .../locations/tree
- [x] #2 Implement service logic to build location hierarchy from database
- [x] #3 Return properly structured tree data with parent-child relationships
- [x] #4 Add endpoint tests and validation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Research and understand existing codebase structure
   - Location schema with parent_id self-reference ✓
   - Existing Locations context module with list functions ✓
   - LocationController with CRUD operations ✓
   - Test patterns and structure ✓

2. Add tree function to Locations context
   - Create list_locations_tree_for_game/1 function
   - Build hierarchical structure from parent-child relationships
   - Handle proper scoping (game-specific)
   - Optimize query with proper preloading

3. Add tree endpoint to LocationController
   - Add tree/2 action function
   - Route: GET /api/games/:game_id/locations/tree
   - Use existing current_scope authentication
   - Return JSON tree structure

4. Update router configuration
   - Add tree route to locations resource block
   - Follow existing pattern in router.ex:83-87

5. Add Swagger documentation
   - Update LocationSwagger module
   - Document tree endpoint schema and response
   - Follow existing swagger patterns

6. Create comprehensive tests
   - Unit tests for tree building logic
   - Controller tests for tree endpoint
   - Test edge cases (empty tree, single level, deep nesting)
   - Test authentication and authorization
   - Follow existing test patterns

7. Validate and test complete implementation
   - Run existing test suite
   - Test tree endpoint manually
   - Verify proper JSON structure
   - Check performance with sample data
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully implemented location tree endpoint with comprehensive functionality:

## Implementation Summary
- Added `list_locations_tree_for_game/1` function to Locations context
- Built efficient tree-building algorithm using Enum.group_by for O(n) performance
- Added tree/2 controller action with proper authentication/authorization
- Added tree/1 JSON renderer for consistent API response format
- Updated router with GET /locations/tree route (placed before resources to avoid conflicts)
- Added complete Swagger documentation with LocationTreeNode and LocationTreeResponse schemas
- Created comprehensive test coverage:
  - 8 controller integration tests covering all scenarios
  - 8 context unit tests for tree building logic
  - Tests cover empty trees, flat structures, deep hierarchies, multiple children, field inclusion, game isolation, and access control

## Technical Approach
- Used hierarchical tree structure with recursive child building
- Implemented proper game-scoped queries for security
- Maintained alphabetical sorting at each level
- Preserved all location fields (id, name, description, type, tags, parent_id)
- Added children array to each node for frontend consumption

## API Endpoint
GET /api/games/{game_id}/locations/tree
- Returns JSON array of root location nodes
- Each node contains full location data plus children array
- Supports deep nesting and proper parent-child relationships
- Authenticated via existing current_scope mechanism

All tests passing (105/105) with no warnings or errors.
<!-- SECTION:NOTES:END -->
