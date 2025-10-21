---
id: task-025
title: Implement entity tree endpoint for games
status: Done
assignee:
  - '@amp'
created_date: '2025-09-30 13:28'
updated_date: '2025-09-30 13:52'
labels:
  - backend
  - api
  - tree-structure
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a new API endpoint that provides a comprehensive view of entity relationships within a game, enabling visualization of the full entity hierarchy and interconnections. This will help game masters understand complex entity relationships and dependencies, supporting better campaign management and narrative planning through a tree-based representation of all linked entities.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 API endpoint GET /games/{id}/tree returns valid JSON response
- [x] #2 Response includes simplified entities with only id and name fields
- [x] #3 Tree structure respects configurable depth limit via query parameter (default 3)
- [x] #4 Relationship metadata from join tables is included (type, description, active status)
- [x] #5 Endpoint handles non-existent game IDs with appropriate 404 response
- [x] #6 Depth parameter validation returns 400 for invalid values
- [x] #7 Tree structure prevents infinite loops in circular relationships
- [x] #8 Response format matches existing API patterns and conventions
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Phase 1: Core EntityTree Module (2 days)

### 1.1 Create GameMasterCore.EntityTree context module
- Location: `lib/game_master_core/entity_tree.ex`
- Main function: `build_entity_tree(scope, opts \\ [])`
- Options: `depth`, `start_entity_type`, `start_entity_id`
- Return simplified entity tree structure

### 1.2 Implement tree traversal algorithm
- Use breadth-first traversal for consistent depth limiting
- Leverage existing `Links.links_for/1` function for relationship discovery
- Implement cycle detection with MapSet of visited entity IDs
- Create helper functions:
  - `traverse_entity_links/4` (entity, current_depth, max_depth, visited)
  - `simplify_entity/1` (extract id and name only)
  - `format_relationship_metadata/1` (from join table data)

### 1.3 Entity type handling
- Support all 5 entity types: characters, factions, locations, quests, notes
- Handle entity-specific fields and associations
- Create unified entity interface for tree building

## Phase 2: API Implementation (1 day)

### 2.1 GameController endpoint
- Add `tree/2` action to existing `GameController`
- Parse and validate `depth` query parameter (default: 3, max: 10)
- Optional: `start_entity_type` and `start_entity_id` parameters
- Use existing scope-based access control
- Error handling for invalid parameters

### 2.2 JSON response format
- Add `tree/1` function to `GameJSON`
- Create simplified entity format:
  ```elixir
  %{
    id: entity.id,
    name: entity.name,
    type: entity_type,
    relationship_type: metadata.relationship_type,
    description: metadata.description,
    strength: metadata.strength,
    is_active: metadata.is_active,
    metadata: metadata.metadata,
    children: [...]
  }
  ```

### 2.3 Router integration
- Add route: `get "/tree", GameController, :tree` to games scope
- Ensure proper middleware pipeline (session_api, require_session_auth)

## Phase 3: Documentation & Validation (0.5 days)

### 3.1 Swagger documentation
- Add endpoint definition to `GameSwagger`
- Document query parameters and response schema
- Include example responses
- Follow existing documentation patterns

### 3.2 Parameter validation
- Depth parameter: integer between 1-10
- Entity type validation if provided
- Entity ID format validation (UUID)

## Phase 4: Testing (1 day)

### 4.1 Unit tests for EntityTree module
- Test tree building with various depths
- Test cycle detection with circular relationships
- Test entity simplification and metadata formatting
- Test edge cases: empty games, invalid entities

### 4.2 Integration tests for API endpoint
- Test endpoint with various depth parameters
- Test error responses (404, 400)
- Test response format and structure
- Test with complex relationship hierarchies

### 4.3 Performance testing
- Test with large games (many entities)
- Measure response times for deep trees
- Validate memory usage patterns

## Phase 5: Performance Optimization (0.5 days)

### 5.1 Database query optimization
- Implement preloading strategy for related entities
- Consider using `Repo.preload` or custom queries
- Batch load entities at each depth level to avoid N+1

### 5.2 Response optimization
- Consider pagination for very large trees
- Add response size monitoring
- Implement caching if needed

## Implementation Notes

### Key Files to Create/Modify:
- `lib/game_master_core/entity_tree.ex` (new)
- `lib/game_master_core_web/controllers/game_controller.ex` (modify)
- `lib/game_master_core_web/controllers/game_json.ex` (modify)
- `lib/game_master_core_web/router.ex` (modify)
- `lib/game_master_core_web/swagger/game_swagger.ex` (modify)
- `test/game_master_core/entity_tree_test.exs` (new)
- `test/game_master_core_web/controllers/game_controller_test.exs` (modify)

### Leveraging Existing Infrastructure:
- Use `Links.links_for/1` for relationship discovery
- Follow tree patterns from `Locations.build_tree/1` and `Quests.build_tree/1`
- Use existing JSON helpers and response patterns
- Leverage scope-based access control from current controllers
- Follow error handling patterns from existing endpoints

### Technical Considerations:
- Maximum depth limit to prevent abuse (suggest 10)
- Circular relationship detection using visited set
- Memory efficient traversal for large entity graphs
- Consistent entity type handling across all 5 types
- Rich metadata preservation from join tables
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Completed implementation of entity tree endpoint for games.

Key accomplishments:
- EntityTree module provides comprehensive relationship traversal with cycle detection
- API endpoint GET /games/{id}/tree with configurable depth parameter (default 3, max 10)
- Full Swagger documentation with request/response schemas
- Comprehensive test coverage for both module and API endpoint
- Response includes simplified entities with relationship metadata
- Proper error handling for invalid parameters and missing resources
- All existing tests pass, ensuring no regressions

Files modified:
- lib/game_master_core/entity_tree.ex (new)
- lib/game_master_core_web/controllers/game_controller.ex
- lib/game_master_core_web/controllers/game_json.ex
- lib/game_master_core_web/router.ex
- lib/game_master_core_web/swagger/game_swagger.ex
- lib/game_master_core_web/swagger_definitions.ex
- test/game_master_core/entity_tree_test.exs (new)
- test/game_master_core_web/controllers/game_controller_test.exs

The implementation leverages existing Links infrastructure and follows established patterns for API design, error handling, and testing.
<!-- SECTION:NOTES:END -->
