---
id: task-003
title: Implement location tree endpoint
status: In Progress
assignee:
  - '@claude'
created_date: '2025-09-19 09:48'
updated_date: '2025-09-19 15:37'
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
- [ ] #1 Create endpoint route for GET .../locations/tree
- [ ] #2 Implement service logic to build location hierarchy from database
- [ ] #3 Return properly structured tree data with parent-child relationships
- [ ] #4 Add endpoint tests and validation
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
