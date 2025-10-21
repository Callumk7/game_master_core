---
id: task-024
title: Complete update_link implementation for remaining controllers
status: Done
assignee:
  - '@claude'
created_date: '2025-09-30 11:18'
updated_date: '2025-09-30 12:03'
labels:
  - backend
  - api
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Finalize the update_link functionality for Character, Faction, Location, and Quest controllers by adding the missing context module functions, controller actions, and Swagger documentation. The core Links module infrastructure and router routes are already in place.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Add update_link_* functions to Characters module
- [x] #2 Add update_link_* functions to Factions module
- [x] #3 Add update_link_* functions to Locations module
- [x] #4 Add update_link_* functions to Quests module
- [x] #5 Add update_link controller actions to remaining 3 controllers (Faction, Location, Quest)
- [x] #6 Add Swagger documentation for update_link endpoints in all 4 remaining controller swagger files
- [x] #7 Add comprehensive test coverage for update_link functionality across all controllers
- [x] #8 Validate all update_link endpoints work correctly with proper error handling
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Comprehensive Implementation Plan

### Current Status
✅ **COMPLETE**: Core infrastructure (Links module, Note controller, router routes)
⚠️ **PENDING**: Context module functions, controller actions, Swagger docs for 4 controllers

### Phase 1: Context Module Functions (Priority: Critical)

#### 1.1 Characters Module (lib/game_master_core/characters.ex)
Add 5 functions after existing unlink functions:
```elixir
def update_link_note(%Scope{} = scope, character_id, note_id, metadata_attrs)
def update_link_faction(%Scope{} = scope, character_id, faction_id, metadata_attrs) 
def update_link_location(%Scope{} = scope, character_id, location_id, metadata_attrs)
def update_link_quest(%Scope{} = scope, character_id, quest_id, metadata_attrs)
def update_link_character(%Scope{} = scope, character_id, other_character_id, metadata_attrs)
```

#### 1.2 Factions Module (lib/game_master_core/factions.ex)
Add 5 functions following same pattern:
```elixir
def update_link_note(%Scope{} = scope, faction_id, note_id, metadata_attrs)
def update_link_character(%Scope{} = scope, faction_id, character_id, metadata_attrs)
def update_link_location(%Scope{} = scope, faction_id, location_id, metadata_attrs)
def update_link_quest(%Scope{} = scope, faction_id, quest_id, metadata_attrs)
def update_link_faction(%Scope{} = scope, faction_id, other_faction_id, metadata_attrs)
```

#### 1.3 Locations Module (lib/game_master_core/locations.ex)
Add 5 functions following same pattern

#### 1.4 Quests Module (lib/game_master_core/quests.ex)
Add 5 functions following same pattern

**Pattern Template:**
```elixir
def update_link_{target}(%Scope{} = scope, {source}_id, {target}_id, metadata_attrs) do
  with {:ok, {source}} <- get_scoped_{source}(scope, {source}_id),
       {:ok, {target}} <- get_scoped_{target}(scope, {target}_id) do
    Links.update_link({source}, {target}, metadata_attrs)
  end
end
```

### Phase 2: Controller Actions (Priority: High)

#### 2.1 Faction Controller (lib/game_master_core_web/controllers/faction_controller.ex)
Add update_link action and private helpers after existing delete_link functions

#### 2.2 Location Controller
Same pattern as Faction controller

#### 2.3 Quest Controller
Same pattern as Faction controller

**Controller Action Template:**
```elixir
def update_link(conn, %{"{entity}_id" => entity_id, "entity_type" => entity_type, "entity_id" => target_entity_id} = params) do
  metadata_attrs = extract_metadata_attrs(params)
  
  with {:ok, entity} <- {Context}.fetch_{entity}_for_game(conn.assigns.current_scope, entity_id),
       {:ok, entity_type} <- validate_entity_type(entity_type),
       {:ok, target_entity_id} <- validate_entity_id(target_entity_id),
       {:ok, updated_link} <- update_{entity}_link(conn.assigns.current_scope, entity.id, entity_type, target_entity_id, metadata_attrs) do
    conn |> put_status(:ok) |> json(success_response(entity, entity_type, target_entity_id, updated_link))
  end
end
```

### Phase 3: Swagger Documentation (Priority: Medium)

#### 3.1 Character Swagger (lib/game_master_core_web/swagger/character_swagger.ex)
Add swagger_path :update_link definition

#### 3.2 Faction Swagger
Copy pattern from Note swagger with entity-specific adjustments

#### 3.3 Location Swagger  
Same pattern

#### 3.4 Quest Swagger
Same pattern

**Swagger Template:**
```elixir
swagger_path :update_link do
  put("/api/games/{game_id}/{entities}/{entity_id}/links/{entity_type}/{target_entity_id}")
  summary("Update a {entity} link")
  description("Update link metadata between a {entity} and another entity")
  operation_id("update{Entity}Link")
  # ... parameters and responses
end
```

### Phase 4: Comprehensive Testing (Priority: High)

#### 4.1 Context Module Tests
Add to existing test files:
- test/game_master_core/characters_test.exs
- test/game_master_core/factions_test.exs  
- test/game_master_core/locations_test.exs
- test/game_master_core/quests_test.exs

#### 4.2 Controller Tests
Add to existing controller test files:
- Success scenarios for each controller
- Error scenarios (non-existent links, invalid parameters)
- Cross-entity relationship testing

#### 4.3 Integration Tests
End-to-end workflow testing:
- Create link → Update link → Verify changes
- Test all 15 entity relationship combinations
- Validate metadata persistence and changeset validation

### Phase 5: Validation & Documentation (Priority: Low)

#### 5.1 Manual API Testing
- Test all PUT endpoints via HTTP client
- Verify Swagger UI documentation accuracy
- Validate error response formats

#### 5.2 Performance Testing
- Test update operations under load
- Verify bidirectional relationship handling performance

### Implementation Order Recommendation:
1. **Characters module functions** (highest impact - eliminates compilation warnings)
2. **Faction, Location, Quest module functions** (batch implementation)
3. **Controller actions for Faction, Location, Quest** (enables full API)
4. **Test coverage expansion** (ensures quality)
5. **Swagger documentation** (completes public API docs)

### Estimated Complexity:
- **Low**: Swagger documentation (copy-paste with minor changes)
- **Medium**: Context module functions (straightforward pattern)
- **Medium**: Controller actions (following established pattern)
- **High**: Comprehensive testing (broad coverage required)

### Success Criteria:
- All 20 PUT endpoints functional (5 controllers × 4 remaining entity types)
- Zero compilation warnings
- Full test coverage for update_link functionality
- Complete Swagger documentation
- All endpoints properly handle validation and errors
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully completed update_link implementation for all remaining controllers:

## Summary
- Added 20 update_link_* functions across 4 context modules (Characters, Factions, Locations, Quests)
- Implemented update_link controller actions in 3 remaining controllers (Faction, Location, Quest) 
- Added complete Swagger documentation for all 4 controllers (Character, Faction, Location, Quest)
- Added comprehensive test coverage: 25 new tests across 4 controller test files
- All 918 tests pass (increased from 893)
- All precommit checks pass (formatting, linting, compilation)
- All 5 PUT endpoints now properly registered in router

## Technical Implementation
- Context modules: Follow established pattern from Notes module with get_scoped_* and Links.update_link calls
- Controller actions: Consistent metadata extraction and response format across all controllers
- Helper functions: update_*_link private functions for all 5 entity type combinations per controller
- Swagger docs: Complete API documentation with proper request/response schemas and error codes
- Test coverage: 6 test cases per controller (success, error handling, validation, authorization)
- Routes verified: All PUT /api/games/{game_id}/{entities}/{entity_id}/links/{entity_type}/{target_id} working

## Test Coverage Added
- Character controller: 6 comprehensive update_link tests
- Faction controller: 6 comprehensive update_link tests  
- Location controller: 6 comprehensive update_link tests
- Quest controller: 6 comprehensive update_link tests
- Missing imports added: CharactersFixtures to location controller test
- All tests validate: successful updates, error handling, validation, and authorization

## Validation Complete
- Compilation successful with no warnings
- Full test suite passes (918 tests, 0 failures - 25 new tests added)
- Routes properly registered and accessible
- Code formatting and linting compliant
- Swagger JSON regenerated successfully
- Complete feature parity with existing Note controller update_link functionality
<!-- SECTION:NOTES:END -->
