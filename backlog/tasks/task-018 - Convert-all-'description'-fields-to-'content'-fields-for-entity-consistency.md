---
id: task-018
title: Convert all 'description' fields to 'content' fields for entity consistency
status: To Do
assignee: []
created_date: '2025-09-21 08:31'
updated_date: '2025-09-21 09:02'
labels:
  - backend
  - api
  - refactor
dependencies: []
priority: medium
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Unify data structures across all entities by standardizing field names from 'description' to 'content'. This includes updating database schemas, tests, and documentation to maintain consistency.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All database description fields renamed to content in schema definitions
- [ ] #2 All description_plain_text fields renamed to content_plain_text
- [ ] #3 All related tests updated to use content field names
- [ ] #4 Swagger documentation updated to reflect content field naming
- [ ] #5 Database migrations updated in place (no retention strategy needed)
- [ ] #6 Database reset performed after migration updates
- [ ] #7 All API endpoints updated to use content field naming
- [ ] #8 All frontend references updated to use content field naming
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
# Detailed Implementation Analysis for Description → Content Field Migration

## Overview
Based on thorough investigation, the codebase currently has an inconsistent field naming pattern:
- Entities using DESCRIPTION: games, characters, factions, locations  
- Entities using CONTENT: quests, notes

This task will standardize ALL entities to use 'content' fields for consistency.

## Affected Entities and Current State

### 1. GAMES (has description → needs conversion to content)
- **Schema**: lib/game_master_core/games/game.ex
- **Database**: games table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250820121011_create_games.exs

### 2. CHARACTERS (has description → needs conversion to content)  
- **Schema**: lib/game_master_core/characters/character.ex
- **Database**: characters table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250822155841_create_characters.exs

### 3. FACTIONS (has description → needs conversion to content)
- **Schema**: lib/game_master_core/factions/faction.ex
- **Database**: factions table
- **Fields**: `description`, `description_plain_text` 
- **Migration**: priv/repo/migrations/20250824125309_create_factions.exs

### 4. LOCATIONS (has description → needs conversion to content)
- **Schema**: lib/game_master_core/locations/location.ex
- **Database**: locations table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250827175957_create_locations.exs

### 5. QUESTS (already has content - reference implementation)
- **Schema**: lib/game_master_core/quests/quest.ex
- **Database**: quests table
- **Fields**: `content`, `content_plain_text` ✓
- **Migration**: priv/repo/migrations/20250829093129_create_quests.exs

### 6. NOTES (already has content - reference implementation)
- **Schema**: lib/game_master_core/notes/note.ex  
- **Database**: notes table
- **Fields**: `content`, `content_plain_text` ✓
- **Migration**: priv/repo/migrations/20250821085144_create_notes.exs

## Implementation Steps Required

### Phase 1: Database Schema Changes
1. **Update migrations in place** (per user requirement - no retention needed):
   - `20250820121011_create_games.exs`: description → content
   - `20250822155841_create_characters.exs`: description → content
   - `20250824125309_create_factions.exs`: description → content  
   - `20250827175957_create_locations.exs`: description → content
   - `20250918133551_add_plain_text_fields_to_entities.exs`: description_plain_text → content_plain_text

2. **Reset database**: `MIX_ENV=test mix ecto.reset` after migration updates

### Phase 2: Ecto Schema Updates
1. **lib/game_master_core/games/game.ex**: 
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast and validation

2. **lib/game_master_core/characters/character.ex**:
   - Change `field :description` to `field :content`  
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast

3. **lib/game_master_core/factions/faction.ex**:
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text` 
   - Update changeset cast and required validation

4. **lib/game_master_core/locations/location.ex**:
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast

### Phase 3: API Layer Updates
1. **JSON Helpers** (lib/game_master_core_web/views/json_helpers.ex):
   - `game_data/1`: description → content  
   - `character_data/1`: description → content
   - `faction_data/1`: description → content
   - `location_data/1`: description → content
   - All `*_data_with_metadata` functions: update description fields

2. **Controllers**: No changes needed (they use schemas)

### Phase 4: Swagger Documentation Updates
**lib/game_master_core_web/swagger_definitions.ex** - Update all schema definitions:

**Game schemas**:
- `game_schema/0`: description → content fields
- `game_create_params_schema/0`: description → content
- `game_update_params_schema/0`: description → content
- Examples in all game schemas

**Character schemas**:
- `character_schema/0`: description → content
- `character_create_params_schema/0`: description → content  
- `character_update_params_schema/0`: description → content
- `entity_character_schema/0`: description → content
- `linked_character_schema/0`: description → content
- Examples in all character schemas

**Faction schemas**:
- `faction_schema/0`: description → content
- `faction_create_params_schema/0`: description → content
- `faction_update_params_schema/0`: description → content  
- `entity_faction_schema/0`: description → content
- `linked_faction_schema/0`: description → content
- Examples in all faction schemas

**Location schemas**:
- `location_schema/0`: description → content
- `location_create_params_schema/0`: description → content
- `location_update_params_schema/0`: description → content
- `entity_location_schema/0`: description → content  
- `linked_location_schema/0`: description → content
- `location_tree_node_schema/0`: description → content
- Examples in all location schemas

### Phase 5: Test Updates
**All test files** need updates for entities using description → content:

**Core Tests**:
- `test/game_master_core/games_test.exs`: Update @invalid_attrs and test assertions
- `test/game_master_core/characters_test.exs`: Update @invalid_attrs and test data
- `test/game_master_core/factions_test.exs`: Update test data  
- `test/game_master_core/locations_test.exs`: Update test data

**Controller Tests**:
- `test/game_master_core_web/controllers/game_controller_test.exs`
- `test/game_master_core_web/controllers/character_controller_test.exs`
- `test/game_master_core_web/controllers/faction_controller_test.exs`
- `test/game_master_core_web/controllers/location_controller_test.exs`
- `test/game_master_core_web/controllers/admin/*_test.exs` files

**Search patterns to find test updates needed**:
- `grep -r "description.*:" test/` 
- `grep -r "description_plain_text" test/`

### Phase 6: Fixture Updates
**Test fixtures likely need updates**:
- `test/support/*_fixtures.ex` files
- Look for any hardcoded description field references

### Phase 7: Database Reset & Verification
1. Run `MIX_ENV=test mix ecto.reset` 
2. Run `mix test` to verify all tests pass
3. Generate updated swagger: `mix phx.swagger.generate`
4. Verify swagger.json updated correctly

## Risk Assessment
**LOW RISK** - This is purely a field rename with no logic changes:
- No data transformation logic needed
- No external API contracts broken (internal fields only)
- No business logic changes
- Database reset acceptable per user requirements

## Verification Checklist  
- [ ] All migrations updated in place
- [ ] All schemas use content/content_plain_text fields
- [ ] All JSON helpers return content fields
- [ ] All swagger schemas define content fields  
- [ ] All tests use content field names
- [ ] Database resets successfully
- [ ] All tests pass
- [ ] Swagger documentation regenerated
- [ ] No remaining "description" field references in codebase

## Search Commands for Verification
```bash
# Should return NO results after completion:
grep -r "description.*:" lib/ --include="*.ex"
grep -r "description_plain_text" lib/ --include="*.ex" 
grep -r "description.*:" test/ --include="*.exs"

# Should return ONLY quest/note content fields:
grep -r "content.*:" lib/ --include="*.ex"
```
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
# Detailed Implementation Analysis for Description → Content Field Migration

## Overview
Based on thorough investigation, the codebase currently has an inconsistent field naming pattern:
- Entities using DESCRIPTION: games, characters, factions, locations  
- Entities using CONTENT: quests, notes

This task will standardize ALL entities to use 'content' fields for consistency.

## Affected Entities and Current State

### 1. GAMES (has description → needs conversion to content)
- **Schema**: lib/game_master_core/games/game.ex
- **Database**: games table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250820121011_create_games.exs

### 2. CHARACTERS (has description → needs conversion to content)  
- **Schema**: lib/game_master_core/characters/character.ex
- **Database**: characters table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250822155841_create_characters.exs

### 3. FACTIONS (has description → needs conversion to content)
- **Schema**: lib/game_master_core/factions/faction.ex
- **Database**: factions table
- **Fields**: `description`, `description_plain_text` 
- **Migration**: priv/repo/migrations/20250824125309_create_factions.exs

### 4. LOCATIONS (has description → needs conversion to content)
- **Schema**: lib/game_master_core/locations/location.ex
- **Database**: locations table
- **Fields**: `description`, `description_plain_text`
- **Migration**: priv/repo/migrations/20250827175957_create_locations.exs

### 5. QUESTS (already has content - reference implementation)
- **Schema**: lib/game_master_core/quests/quest.ex
- **Database**: quests table
- **Fields**: `content`, `content_plain_text` ✓
- **Migration**: priv/repo/migrations/20250829093129_create_quests.exs

### 6. NOTES (already has content - reference implementation)
- **Schema**: lib/game_master_core/notes/note.ex  
- **Database**: notes table
- **Fields**: `content`, `content_plain_text` ✓
- **Migration**: priv/repo/migrations/20250821085144_create_notes.exs

## Implementation Steps Required

### Phase 1: Database Schema Changes
1. **Update migrations in place** (per user requirement - no retention needed):
   - `20250820121011_create_games.exs`: description → content
   - `20250822155841_create_characters.exs`: description → content
   - `20250824125309_create_factions.exs`: description → content  
   - `20250827175957_create_locations.exs`: description → content
   - `20250918133551_add_plain_text_fields_to_entities.exs`: description_plain_text → content_plain_text

2. **Reset database**: `MIX_ENV=test mix ecto.reset` after migration updates

### Phase 2: Ecto Schema Updates
1. **lib/game_master_core/games/game.ex**: 
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast and validation

2. **lib/game_master_core/characters/character.ex**:
   - Change `field :description` to `field :content`  
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast

3. **lib/game_master_core/factions/faction.ex**:
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text` 
   - Update changeset cast and required validation

4. **lib/game_master_core/locations/location.ex**:
   - Change `field :description` to `field :content`
   - Change `field :description_plain_text` to `field :content_plain_text`
   - Update changeset cast

### Phase 3: API Layer Updates
1. **JSON Helpers** (lib/game_master_core_web/views/json_helpers.ex):
   - `game_data/1`: description → content  
   - `character_data/1`: description → content
   - `faction_data/1`: description → content
   - `location_data/1`: description → content
   - All `*_data_with_metadata` functions: update description fields

2. **Controllers**: No changes needed (they use schemas)

### Phase 4: Swagger Documentation Updates
**lib/game_master_core_web/swagger_definitions.ex** - Update all schema definitions:

**Game schemas**:
- `game_schema/0`: description → content fields
- `game_create_params_schema/0`: description → content
- `game_update_params_schema/0`: description → content
- Examples in all game schemas

**Character schemas**:
- `character_schema/0`: description → content
- `character_create_params_schema/0`: description → content  
- `character_update_params_schema/0`: description → content
- `entity_character_schema/0`: description → content
- `linked_character_schema/0`: description → content
- Examples in all character schemas

**Faction schemas**:
- `faction_schema/0`: description → content
- `faction_create_params_schema/0`: description → content
- `faction_update_params_schema/0`: description → content  
- `entity_faction_schema/0`: description → content
- `linked_faction_schema/0`: description → content
- Examples in all faction schemas

**Location schemas**:
- `location_schema/0`: description → content
- `location_create_params_schema/0`: description → content
- `location_update_params_schema/0`: description → content
- `entity_location_schema/0`: description → content  
- `linked_location_schema/0`: description → content
- `location_tree_node_schema/0`: description → content
- Examples in all location schemas

### Phase 5: Test Updates
**All test files** need updates for entities using description → content:

**Core Tests**:
- `test/game_master_core/games_test.exs`: Update @invalid_attrs and test assertions
- `test/game_master_core/characters_test.exs`: Update @invalid_attrs and test data
- `test/game_master_core/factions_test.exs`: Update test data  
- `test/game_master_core/locations_test.exs`: Update test data

**Controller Tests**:
- `test/game_master_core_web/controllers/game_controller_test.exs`
- `test/game_master_core_web/controllers/character_controller_test.exs`
- `test/game_master_core_web/controllers/faction_controller_test.exs`
- `test/game_master_core_web/controllers/location_controller_test.exs`
- `test/game_master_core_web/controllers/admin/*_test.exs` files

**Search patterns to find test updates needed**:
- `grep -r "description.*:" test/` 
- `grep -r "description_plain_text" test/`

### Phase 6: Fixture Updates
**Test fixtures likely need updates**:
- `test/support/*_fixtures.ex` files
- Look for any hardcoded description field references

### Phase 7: Database Reset & Verification
1. Run `MIX_ENV=test mix ecto.reset` 
2. Run `mix test` to verify all tests pass
3. Generate updated swagger: `mix phx.swagger.generate`
4. Verify swagger.json updated correctly

## Risk Assessment
**LOW RISK** - This is purely a field rename with no logic changes:
- No data transformation logic needed
- No external API contracts broken (internal fields only)
- No business logic changes
- Database reset acceptable per user requirements

## Verification Checklist  
- [ ] All migrations updated in place
- [ ] All schemas use content/content_plain_text fields
- [ ] All JSON helpers return content fields
- [ ] All swagger schemas define content fields  
- [ ] All tests use content field names
- [ ] Database resets successfully
- [ ] All tests pass
- [ ] Swagger documentation regenerated
- [ ] No remaining "description" field references in codebase

## Search Commands for Verification
```bash
# Should return NO results after completion:
grep -r "description.*:" lib/ --include="*.ex"
grep -r "description_plain_text" lib/ --include="*.ex" 
grep -r "description.*:" test/ --include="*.exs"

# Should return ONLY quest/note content fields:
grep -r "content.*:" lib/ --include="*.ex"
```
<!-- SECTION:NOTES:END -->
