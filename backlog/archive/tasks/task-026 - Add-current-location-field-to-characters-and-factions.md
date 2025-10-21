---
id: task-026
title: Add current location field to characters and factions
status: To Do
assignee: []
created_date: '2025-10-02 14:53'
updated_date: '2025-10-02 14:59'
labels:
  - backend
  - database
  - api
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a location_id field to both characters and factions to track their current location, separate from the existing relationship system which tracks general location associations.

This will allow us to mark where a character or faction is currently located, distinct from places they have relationships with or have visited.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Character schema has location_id field with belongs_to relationship
- [ ] #2 Faction schema has location_id field with belongs_to relationship
- [ ] #3 Database migration creates location_id columns in both tables
- [ ] #4 Character changeset accepts location_id parameter
- [ ] #5 Faction changeset accepts location_id parameter
- [ ] #6 API endpoints support setting/updating current location
- [ ] #7 Foreign key constraints prevent invalid location references
- [ ] #8 Current location can be null (characters/factions may not have current location)

- [ ] #9 Tests cover setting/updating current location for characters
- [ ] #10 Tests cover setting/updating current location for factions
- [ ] #11 Tests validate foreign key constraints and game boundaries
- [ ] #12 Tests cover null/empty current location scenarios
- [ ] #13 Swagger documentation updated for character endpoints
- [ ] #14 Swagger documentation updated for faction endpoints
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create database migration to add location_id to characters and factions tables
2. Update Character schema to include belongs_to :current_location, Location
3. Update Faction schema to include belongs_to :current_location, Location
4. Update Character changeset to cast location_id
5. Update Faction changeset to cast location_id
6. Update API documentation (Swagger) to include location_id
7. Test the implementation with valid and invalid location IDs
8. Ensure foreign key constraints work properly
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Current State Analysis

### Existing Infrastructure
- Location entity already exists with full CRUD functionality
- Character-location and faction-location relationship tables already exist (character_locations, faction_locations)
- These relationship tables support rich metadata (relationship_type, description, strength, is_active, metadata)
- Current relationship system is many-to-many for tracking associations/history

### Key Findings
- Characters have member_of_faction_id but NO current location field
- Factions have NO current location field
- Location system supports hierarchical structure (parent/child relationships)
- Location types: continent, nation, region, city, settlement, building, complex

### Database Structure
- Characters table: exists with game_id, user_id, member_of_faction_id
- Factions table: exists with game_id, user_id
- Locations table: exists with game_id, user_id, parent_id
- All use binary_id (UUID) primary keys

### Implementation Requirements

#### Migration
```elixir
defmodule GameMasterCore.Repo.Migrations.AddCurrentLocationToCharactersAndFactions do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :current_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
    end

    alter table(:factions) do
      add :current_location_id, references(:locations, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:characters, [:current_location_id])
    create index(:factions, [:current_location_id])
  end
end
```

#### Schema Changes
Character.ex:
- Add `belongs_to :current_location, Location`
- Add `:current_location_id` to changeset cast
- Add foreign_key_constraint for :current_location_id

Faction.ex:
- Add `belongs_to :current_location, Location`  
- Add `:current_location_id` to changeset cast
- Add foreign_key_constraint for :current_location_id

#### API Considerations
- Current location should be optional (nullable)
- Must validate location exists and belongs to same game
- Should be included in JSON responses
- Should be updatable via PUT/PATCH endpoints

### Key Design Decisions
1. Use `on_delete: :nilify_all` - if location is deleted, set current_location_id to null
2. Separate from relationship system - this is for "current" location, not historical/associations
3. Both entities can exist without a current location (nullable field)
4. Must respect game boundaries - can only reference locations in same game
<!-- SECTION:NOTES:END -->
