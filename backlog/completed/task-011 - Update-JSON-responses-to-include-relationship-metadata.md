---
id: task-011
title: Update JSON responses to include relationship metadata
status: Done
assignee:
  - '@gemini'
created_date: '2025-09-19 11:13'
updated_date: '2025-09-19 11:37'
labels:
  - backend
  - api
  - enhancement
dependencies: []
priority: high
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fix mismatch between Swagger documentation and actual JSON responses. The Swagger docs promise LinkedCharacter, LinkedFaction, etc. schemas with metadata fields, but actual responses only return basic entity data without relationship metadata.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Update Links module get_*_for_* functions to return entities with relationship metadata
- [x] #2 Create helper functions in JSONHelpers for all entity types with metadata
- [x] #3 Update all 5 JSON view files to use metadata helper functions
- [x] #4 Update existing tests to expect new response format with metadata
- [x] #5 Verify all /links endpoints return data matching Swagger documentation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Phase 1: Links Module Updates (25 functions)

Update all `get_*_for_*` functions in `lib/game_master_core/links.ex` to return structured data with metadata:

**Pattern to Apply**:
```elixir
# OLD:
from(n in Note,
  join: cn in CharacterNote,
  on: cn.note_id == n.id,
  where: cn.character_id == ^character.id
)
|> Repo.all()

# NEW:
from(n in Note,
  join: cn in CharacterNote,
  on: cn.note_id == n.id,
  where: cn.character_id == ^character.id,
  select: %{
    entity: n,
    relationship_type: cn.relationship_type,
    description: cn.description,
    strength: cn.strength,
    is_active: cn.is_active,
    metadata: cn.metadata
  }
)
|> Repo.all()
```

**Functions to Update**:
- `get_notes_for_character/1`
- `get_characters_for_note/1`  
- `get_factions_for_character/1`
- `get_characters_for_faction/1`
- `get_locations_for_character/1`
- `get_characters_for_location/1`
- `get_quests_for_character/1`
- `get_characters_for_quest/1`
- `get_characters_for_character/1`
- `get_notes_for_faction/1`
- `get_factions_for_note/1`
- `get_locations_for_faction/1`
- `get_factions_for_location/1`
- `get_quests_for_faction/1`
- `get_factions_for_quest/1`
- `get_factions_for_faction/1`
- `get_notes_for_location/1`
- `get_locations_for_note/1`
- `get_quests_for_location/1`
- `get_locations_for_quest/1`
- `get_locations_for_location/1`
- `get_notes_for_quest/1`
- `get_quests_for_note/1`
- `get_quests_for_quest/1`
- `get_notes_for_note/1`

### Phase 2: JSONHelpers Updates

Add metadata helper functions to `lib/game_master_core_web/views/json_helpers.ex`:

```elixir
def character_data_with_metadata(%{entity: character, relationship_type: relationship_type, description: description, strength: strength, is_active: is_active, metadata: metadata}) do
  character_data(character)
  |> Map.merge(%{
    relationship_type: relationship_type,
    description_meta: description,
    strength: strength,
    is_active: is_active,
    metadata: metadata
  })
end

def faction_data_with_metadata(%{entity: faction, relationship_type: relationship_type, description: description, strength: strength, is_active: is_active, metadata: metadata}) do
  faction_data(faction)
  |> Map.merge(%{
    relationship_type: relationship_type,
    description_meta: description,
    strength: strength,
    is_active: is_active,
    metadata: metadata
  })
end

# Similar functions for location_data_with_metadata, quest_data_with_metadata, note_data_with_metadata
```

### Phase 3: JSON View Updates

Update all JSON view files to use metadata helper functions:

**File**: `lib/game_master_core_web/controllers/character_json.ex`
```elixir
# OLD:
characters: for(char <- characters, do: character_data(char))

# NEW:
characters: for(char <- characters, do: character_data_with_metadata(char))
```

**Files to Update**:
- `lib/game_master_core_web/controllers/character_json.ex`
- `lib/game_master_core_web/controllers/faction_json.ex`
- `lib/game_master_core_web/controllers/location_json.ex`
- `lib/game_master_core_web/controllers/quest_json.ex`
- `lib/game_master_core_web/controllers/note_json.ex`

### Phase 4: Test Updates

Update all existing tests that expect the old response format:

**Pattern to Apply**:
```elixir
# OLD:
assert note1 in linked_notes

# NEW:
assert %{entity: note1, relationship_type: _, description: _, strength: _, is_active: _, metadata: _} in linked_notes
# OR extract entities for comparison:
linked_note_entities = Enum.map(linked_notes, & &1.entity)
assert note1 in linked_note_entities
```

**Test Files to Update**:
- `test/game_master_core/characters_test.exs`
- `test/game_master_core/factions_test.exs`  
- `test/game_master_core/locations_test.exs`
- `test/game_master_core/quests_test.exs`
- `test/game_master_core/notes_test.exs`
- All controller tests for `/links` endpoints

### Phase 5: Integration Testing

1. Run all tests and fix failures
2. Test API endpoints manually to verify metadata is included
3. Verify response structure matches Swagger documentation
4. Test backward compatibility with existing link creation

### Breaking Change Impact

**Before**:
```json
{
  "data": {
    "character_id": "...",
    "links": {
      "factions": [
        {"id": "...", "name": "Red Dragons", "description": "..."}
      ]
    }
  }
}
```

**After**:
```json
{
  "data": {
    "character_id": "...", 
    "links": {
      "factions": [
        {
          "id": "...",
          "name": "Red Dragons",
          "description": "...",
          "relationship_type": "enemy",
          "description_meta": "Sworn enemy after the betrayal",
          "strength": 9,
          "is_active": true,
          "metadata": {"conflict_start": "2023-01-15"}
        }
      ]
    }
  }
}
```
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Updated all `get_*_for_*` functions in `lib/game_master_core/links.ex` to return a map with the entity and relationship metadata.
- Added `*_data_with_metadata` functions to `lib/game_master_core_web/views/json_helpers.ex` to format the new data structure for JSON responses.
- Updated all `*_json.ex` files to use the new `*_data_with_metadata` functions in their `links/1` functions.
- Updated all tests to handle the new data structure. The tests now extract the entity from the map before making assertions.
<!-- SECTION:NOTES:END -->
