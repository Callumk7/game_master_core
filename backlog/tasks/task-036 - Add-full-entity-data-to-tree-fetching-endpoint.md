---
id: task-036
title: Add full entity data to tree fetching endpoint
status: To Do
assignee: []
created_date: '2025-10-30 17:11'
labels:
  - enhancement
  - api
  - backend
  - feature
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enhance the existing entity tree endpoint (`/api/games/:game_id/tree`) to return complete entity data (all fields) along with link metadata when traversing entity relationships. Currently the tree endpoint returns only basic entity information (id, name, type) for nodes. Users need access to all entity fields (content, tags, pinned, etc.) and complete link metadata to build comprehensive entity relationship visualizations without making additional API calls.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 API accepts entity_id, entity_type, and depth parameters (depth already supported, verify entity_id/type work correctly)
- [ ] #2 Endpoint recursively fetches linked entities up to specified depth with cycle detection
- [ ] #3 Response includes full entity data for all nodes (id, name, content, content_plain_text, tags, pinned, and type-specific fields like level, class, race for characters)
- [ ] #4 Response includes complete link metadata (relationship_type, description, strength, is_active, metadata JSONB field)
- [ ] #5 Response includes entity-specific link fields (is_primary, faction_role for character-faction; is_current_location for character-location, etc.)
- [ ] #6 Depth parameter validation enforces 1-10 range with proper error messages
- [ ] #7 API returns proper error responses for invalid entity types or non-existent IDs
- [ ] #8 Response structure is documented in Swagger/OpenAPI specs
- [ ] #9 Existing tests updated to verify full data structure is returned
- [ ] #10 Performance is acceptable for depth=3 with 50+ linked entities
<!-- AC:END -->

## Technical Context

**Existing Implementation:**
- Module: `GameMasterCore.EntityTree` (`lib/game_master_core/entity_tree.ex`)
- Controller: `GameMasterCoreWeb.GameController.tree/2`
- Route: `GET /api/games/:game_id/tree`
- Current function: `build_entity_tree(scope, opts)` with depth, start_entity_type, start_entity_id support

**Related Modules:**
- `GameMasterCore.Links` - Provides `links_for/1` with full metadata and preloaded entities
- Entity schemas: `Characters`, `Locations`, `Factions`, `Quests`, `Notes`
- All join tables have rich metadata: relationship_type, description, strength, is_active, metadata

**Current Limitations:**
- Tree nodes only return basic fields: `%{id: id, name: name, type: type, children: children}`
- Link metadata is partially included but may not have all fields
- Entity-specific fields are not included

## Suggested Approach

1. **Enhance `EntityTree` module**:
   - Modify node building to include full entity struct data
   - Ensure all preloads are performed for entity fields
   - Include all link metadata fields when building children

2. **Update response formatting**:
   - Map full entity structs into response nodes
   - Include entity-specific fields conditionally based on type
   - Flatten link metadata into each child relationship

3. **Update Swagger docs**:
   - Document complete response schema with all entity types
   - Show example responses with full data structure
   - Document all possible link metadata fields

4. **Testing**:
   - Verify full entity data is present for all entity types
   - Test link metadata completeness for all join table types
   - Test depth limiting and cycle detection still work
   - Performance test with realistic data volumes

## Example Response Structure

```json
{
  "tree": {
    "id": "uuid",
    "name": "Aragorn",
    "type": "character",
    "content": "<p>Ranger of the North...</p>",
    "content_plain_text": "Ranger of the North...",
    "tags": ["ranger", "hero", "dunedain"],
    "pinned": true,
    "level": 20,
    "class": "Ranger",
    "race": "Human",
    "alive": true,
    "children": [
      {
        "id": "uuid",
        "name": "Fellowship of the Ring",
        "type": "faction",
        "content": "<p>Nine companions...</p>",
        "content_plain_text": "Nine companions...",
        "tags": ["fellowship"],
        "pinned": false,
        "relationship": {
          "type": "character_faction",
          "relationship_type": "leader",
          "description": "One of the nine walkers",
          "strength": 10,
          "is_active": true,
          "is_primary": true,
          "faction_role": "Leader",
          "metadata": {}
        },
        "children": []
      },
      {
        "id": "uuid",
        "name": "Rivendell",
        "type": "location",
        "location_type": "settlement",
        "content": "<p>Last Homely House...</p>",
        "tags": ["elven", "safe-haven"],
        "relationship": {
          "type": "character_location",
          "relationship_type": "visited",
          "description": "Stayed before quest began",
          "strength": 7,
          "is_active": false,
          "is_current_location": false,
          "metadata": {}
        },
        "children": []
      }
    ]
  }
}
```

## Files to Modify

- `lib/game_master_core/entity_tree.ex` - Core tree building logic
- `lib/game_master_core_web/controllers/game_controller.ex` - Tree endpoint handler (possibly)
- `lib/game_master_core_web/swagger_schemas.ex` - API documentation
- `test/game_master_core/entity_tree_test.exs` - Unit tests
- `test/game_master_core_web/controllers/game_controller_test.exs` - Integration tests
