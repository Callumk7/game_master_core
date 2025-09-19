---
id: task-002
title: Add metadata to existing join tables
status: Done
assignee:
  - '@claude'
created_date: '2025-09-19 09:48'
updated_date: '2025-09-19 10:56'
labels:
  - backend
  - database
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enhance all link join tables by adding metadata columns to support richer relationship information and improve the linking system
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Identify all link join tables (character_faction_links, location_quest_links, character_character_links, etc.)
- [x] #2 Create database migrations adding metadata columns (relationship_type, description, rank) to each table
- [x] #3 Update corresponding models in application code to reflect new columns

- [x] #4 Update Swagger documentation generation files to include new metadata fields in link requests and responses
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Analyze current join tables and categorize by metadata needs
2. Create comprehensive migration file adding metadata columns to all join tables
3. Update all join table schema modules to include new metadata fields
4. Update changesets to handle the new fields
5. Test the changes with existing functionality
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Plan for Task 002: Add metadata to existing join tables

### 1. Current Join Tables Analysis

Identified all existing join tables in the system:

**Cross-Entity Join Tables** (need metadata columns):
- `character_factions`
- `character_locations` 
- `character_notes`
- `faction_locations`
- `faction_notes`
- `location_notes`
- `quests_characters`
- `quests_factions`
- `quests_locations`
- `quests_notes`

**Self-Referencing Join Tables** (already have `relationship_type`, need additional metadata):
- `character_characters` ✓ (has `relationship_type`)
- `faction_factions` ✓ (has `relationship_type`)
- `location_locations` ✓ (has `relationship_type`)
- `quest_quests` ✓ (has `relationship_type`)
- `note_notes` ✓ (has `relationship_type`)

### 2. Proposed Metadata Columns

#### **Universal Metadata Fields** (for all join tables):
1. **`relationship_type`** (:string) - Categorizes the type of relationship
2. **`description`** (:text) - Free-form description of the relationship context
3. **`strength`** (:integer, 1-10) - Relationship strength/importance ranking
4. **`is_active`** (:boolean, default: true) - Whether the relationship is currently active
5. **`metadata`** (:map) - JSON field for additional flexible metadata

#### **Specific Relationship Type Examples**:
- **Character-Faction**: "ally", "enemy", "member", "leader", "informant"
- **Character-Character**: "friend", "enemy", "family", "mentor", "rival"
- **Character-Location**: "lives_in", "owns", "visited", "hiding_in"
- **Quest-Character**: "quest_giver", "target", "ally", "obstacle"
- **Quest-Location**: "takes_place_in", "starts_in", "destination"

### 3. Migration Strategy

**Single comprehensive migration** that adds all metadata columns to all join tables in one go to:
- Maintain consistency across tables
- Reduce migration complexity
- Allow for rollback if issues arise

### 4. Schema Updates Required

**For tables that don't have `relationship_type`** (10 tables):\n- Add all 5 metadata fields\n- Update changeset to cast new fields\n- Add validation for strength (1-10 range)\n\n**For tables that already have `relationship_type`** (5 tables):\n- Add remaining 4 metadata fields (description, strength, is_active, metadata)\n- Update changeset to cast new fields\n\n### 5. Changeset Validation Rules\n\n- `relationship_type`: Optional string, no specific validation (flexible)\n- `description`: Optional text field\n- `strength`: Optional integer, range 1-10\n- `is_active`: Boolean with default true\n- `metadata`: Optional map field for JSON data

### Implementation Complete

✅ **Migration Created**: `20250919102132_add_metadata_to_join_tables.exs`
- Added metadata columns to all 15 join tables
- Cross-entity tables: Added all 5 fields (relationship_type, description, strength, is_active, metadata)
- Self-referencing tables: Added 4 fields (description, strength, is_active, metadata) since they already had relationship_type

✅ **Schemas Updated**: All 15 join table schemas updated
- **Cross-entity**: character_factions, character_locations, character_notes, faction_locations, faction_notes, location_notes, quests_characters, quests_factions, quests_locations, quests_notes
- **Self-referencing**: character_characters, faction_factions, location_locations, quest_quests, note_notes

✅ **Validation Added**:
- strength field validates range 1-10
- All new fields properly cast in changesets
- Existing validations preserved

✅ **Testing Complete**:
- Migration ran successfully
- All 686 tests pass
- Project compiles without errors
- Precommit checks pass

### Outstanding Task: Swagger Documentation Update

❌ **Missing**: Need to update Swagger documentation generation functions to reflect new metadata fields

**What needs to be updated**:
1. `link_request_schema` in `swagger_definitions.ex` - Add new metadata fields for link creation
2. Link response schemas - Include metadata fields in link list responses  
3. Swagger endpoint documentation - Update parameter descriptions for metadata fields

**New fields to document**:
- `relationship_type` (string, optional) - Type of relationship
- `description` (text, optional) - Free-form description 
- `strength` (integer 1-10, optional) - Relationship strength
- `is_active` (boolean, optional, default: true) - Whether relationship is active
- `metadata` (map/JSON, optional) - Additional flexible metadata

**Impact**: API consumers need updated documentation to use new metadata features in the linking system.

### ✅ Swagger Documentation Updates Complete

**Updated Components**:
1. **`link_request_schema`**: Added all 5 new metadata fields with proper validation, examples, and documentation
2. **Link endpoint parameters**: Switched from query parameters to JSON request body using `Schema.ref(:LinkRequest)` for cleaner API design
3. **Link response schemas**: Created new `LinkedCharacter`, `LinkedFaction`, `LinkedLocation`, `LinkedQuest`, and `LinkedNote` schemas that include both entity data and relationship metadata
4. **All 5 entity swagger files updated**: character, faction, location, quest, and note swagger endpoints now use proper JSON body parameters

**Key Improvements**:
- API consumers can now include relationship metadata when creating links
- Link responses include full relationship context (type, description, strength, active status, custom metadata)
- Cleaner API design using JSON bodies instead of multiple query parameters
- Comprehensive examples and validation in swagger documentation

**Testing**: All 693 tests pass, swagger.json regenerated successfully

### Controller Updates Complete

All 5 controllers (character, faction, location, quest, note) have been updated to:
1. Extract metadata fields from request parameters into metadata_attrs map
2. Pass metadata through to service layer link functions
3. Updated all private create_*_link helper functions to accept metadata parameter

**Pattern Used**: Consistent metadata extraction pattern across all controllers:
```elixir
metadata_attrs = %{
  relationship_type: Map.get(params, "relationship_type"),
  description: Map.get(params, "description"),
  strength: Map.get(params, "strength"),
  is_active: Map.get(params, "is_active"),
  metadata: Map.get(params, "metadata")
}
```

### Service Layer Updates Complete

All 4 service modules (Characters, Factions, Locations, Quests, Notes) updated:
- All link_* functions now accept optional metadata_attrs parameter with %{} default
- Pass metadata through to Links.link/3 function
- Maintains backward compatibility with existing code

### Links Module Updates Complete

- Main Links.link/3 function updated to accept metadata_attrs parameter
- All 15 create_*_link private functions updated to merge metadata into changeset attributes
- Pattern: `Map.merge(%{entity_1_id: id1, entity_2_id: id2}, metadata_attrs)`

### Testing Complete

✅ **Full System Test**: All 693 tests pass
✅ **Compilation**: Project compiles without errors  
✅ **Precommit**: All quality checks pass
✅ **Swagger Generation**: swagger.json regenerated successfully

### Complete Implementation Summary

The metadata linking system is now fully operational:

1. **Database Layer**: 15 join tables enhanced with 5 metadata columns (relationship_type, description, strength, is_active, metadata)
2. **Schema Layer**: All join table schemas updated with metadata fields and validation
3. **Links Module**: Core linking system updated to handle metadata in all 15 link types
4. **Service Layer**: All 5 service modules (Characters, Factions, Locations, Quests, Notes) updated with metadata support
5. **Controller Layer**: All 5 controllers updated to extract and pass metadata fields
6. **API Layer**: Swagger documentation updated for metadata fields in link requests and responses

**Backward Compatibility**: The old method of sending just entity_id and entity_type still works perfectly. Phoenix merges body and query params, so existing API consumers will continue to work unchanged while new consumers can take advantage of the rich metadata fields.

**API Enhancement**: Link creation now supports comprehensive relationship metadata including type, description, strength rating, active status, and flexible JSON metadata for future extensions.
<!-- SECTION:NOTES:END -->
