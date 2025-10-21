---
id: task-020
title: Add entity_type field to tree entities
status: Done
assignee:
  - '@claude'
created_date: '2025-09-23 09:59'
updated_date: '2025-09-23 10:43'
labels:
  - backend
  - api
  - tree
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add entity_type field to all tree node responses to enable proper client URL construction. Currently tree APIs return nodes without entity_type, preventing the React client from building correct navigation URLs like /games/$gameId/${parentNode.entityType}s/$id.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All tree API responses include entity_type field for every node including parent nodes
- [x] #2 Location tree nodes have entity_type: "location"
- [x] #3 Quest tree nodes have entity_type: "quest"
- [x] #4 Character notes tree nodes have appropriate entity_type values ("note", "character", etc.)
- [x] #5 Swagger documentation is updated to include the new entity_type field in all tree node schemas
- [x] #6 All existing tests pass after changes
- [x] #7 New tests verify entity_type field is correctly set in all tree responses
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Phase 1: Backend Tree Building Functions

1. **Locations Tree (lib/game_master_core/locations.ex)**
   - Modify `build_location_node/2` function
   - Add `entity_type: "location"` to the map structure
   - Current structure: `%{id, name, content, type, tags, parent_id, children}`
   - New structure: `%{id, name, content, type, tags, parent_id, children, entity_type}`

2. **Quests Tree (lib/game_master_core/quests.ex)**
   - Modify `build_quest_node/2` function
   - Add `entity_type: "quest"` to the map structure
   - Current structure: `%{id, name, content, content_plain_text, tags, parent_id, children}`
   - New structure: `%{id, name, content, content_plain_text, tags, parent_id, children, entity_type}`

3. **Character Notes Tree (lib/game_master_core/notes.ex)**
   - Modify `add_note_children/2` function
   - Add `entity_type: "note"` to note nodes
   - The character notes tree only contains Note entities, so all should be "note"
   - Update in `Map.put(note, :children, children_with_trees)` to also add entity_type

### Phase 2: JSON Response Updates

4. **Character JSON (lib/game_master_core_web/controllers/character_json.ex)**
   - Update `note_tree_data/1` function to include entity_type from note data
   - Ensure the entity_type is passed through in the JSON response

### Phase 3: Swagger Schema Updates

5. **Update Swagger Definitions (lib/game_master_core_web/swagger_definitions.ex)**
   - Add `entity_type` field to `location_tree_node_schema/0`
   - Add `entity_type` field to `quest_tree_node_schema/0`
   - Add `entity_type` field to any note tree schemas
   - Set as required string field with appropriate enum values

### Phase 4: Testing

6. **Update Existing Tests**
   - Update location controller tests to expect `entity_type: "location"`
   - Update quest controller tests to expect `entity_type: "quest"`
   - Update character controller tests to expect `entity_type: "note"` in notes_tree
   - Review and update context tests (locations_test.exs, quests_test.exs, notes_test.exs)

7. **Add New Test Cases**
   - Verify entity_type field is present in all tree responses
   - Verify correct entity_type values for each tree type
   - Test mixed hierarchies in character notes if applicable

### Phase 5: Validation & Documentation

8. **Run Test Suite & Linting**
   - Run `mix test` to ensure all tests pass
   - Run `mix precommit` to check linting and formatting
   - Verify Swagger docs generate correctly

### Key Implementation Details

- **Location Trees**: Always `entity_type: "location"`
- **Quest Trees**: Always `entity_type: "quest"`
- **Character Notes Trees**: Always `entity_type: "note"` (only contains Note entities)
- **Backward Compatibility**: Adding new field shouldn't break existing clients
- **Consistency**: All tree nodes at every level must include entity_type

### Files to Modify

1. `lib/game_master_core/locations.ex` - build_location_node/2
2. `lib/game_master_core/quests.ex` - build_quest_node/2  
3. `lib/game_master_core/notes.ex` - add_note_children/2
4. `lib/game_master_core_web/controllers/character_json.ex` - note_tree_data/1
5. `lib/game_master_core_web/swagger_definitions.ex` - tree schemas
6. Test files for all above modules
7. Controller test files

### Expected API Response Changes

**Before:**
```json
{
  "data": [
    {
      "id": "123",
      "name": "Forest",
      "type": "region",
      "children": []
    }
  ]
}
```

**After:**
```json
{
  "data": [
    {
      "id": "123", 
      "name": "Forest",
      "type": "region", 
      "entity_type": "location",
      "children": []
    }
  ]
}
```
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Summary

Successfully implemented entity_type field for all tree entities. Added entity_type to location, quest, and character notes tree responses.

## Changes Made

### Backend Tree Building Functions
1. **lib/game_master_core/locations.ex**: Added `entity_type: "location"` to `build_location_node/2`
2. **lib/game_master_core/quests.ex**: Added `entity_type: "quest"` to `build_quest_node/2`
3. **lib/game_master_core/notes.ex**: Added `entity_type: "note"` to `add_note_children/2`
4. **lib/game_master_core_web/controllers/character_json.ex**: Updated `note_tree_data/1` to preserve entity_type

### Swagger Schema Updates
5. **lib/game_master_core_web/swagger_definitions.ex**: Added entity_type field to:
   - `location_tree_node_schema` (enum: ["location"])
   - `quest_tree_node_schema` (enum: ["quest"])
   - `note_tree_node_schema` (enum: ["note"])
   - Updated all examples to include entity_type

### Test Updates
6. Added entity_type tests to:
   - `test/game_master_core/locations_test.exs`
   - `test/game_master_core/quests_test.exs`
   - `test/game_master_core/notes_test.exs`
   - `test/game_master_core_web/controllers/location_controller_test.exs`

## API Response Examples

**Location Tree Response:**
```json
{
  "data": [
    {
      "id": "123",
      "name": "Forest",
      "type": "region",
      "entity_type": "location",
      "children": [...]
    }
  ]
}
```

**Quest Tree Response:**
```json
{
  "data": [
    {
      "id": "456", 
      "name": "Main Quest",
      "entity_type": "quest",
      "children": [...]
    }
  ]
}
```

**Character Notes Tree Response:**
```json
{
  "data": {
    "character_id": "789",
    "notes_tree": [
      {
        "id": "101",
        "name": "Character Note",
        "entity_type": "note",
        "children": [...]
      }
    ]
  }
}
```

## Testing

- All new tests pass
- All existing tree tests continue to pass
- API endpoints correctly return entity_type field
- Swagger documentation updated
- Precommit checks pass

## Backward Compatibility

Adding the entity_type field is backward compatible - existing clients will ignore the new field while new clients can use it for URL construction.
<!-- SECTION:NOTES:END -->
