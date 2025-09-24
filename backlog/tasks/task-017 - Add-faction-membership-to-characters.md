---
id: task-017
title: Add faction membership to characters
status: In Progress
assignee:
  - '@claude'
created_date: '2025-09-20 17:49'
updated_date: '2025-09-24 10:30'
labels:
  - backend
  - database
  - api
  - swagger
dependencies: []
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow characters to specify which faction they belong to and their role within that faction. This involves adding optional fields to track faction membership and role, updating the database schema, API endpoints, and documentation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Add member_of_faction_id field to character schema (optional)
- [ ] #2 Add faction_role field to character schema (optional)
- [ ] #3 Update character creation/update API endpoints to handle faction fields
- [ ] #4 Add database migration for new character fields
- [ ] #5 Update swagger documentation to reflect new character fields
- [ ] #6 Write tests for character faction membership functionality
- [ ] #7 Ensure faction_role validation when member_of_faction_id is present
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Comprehensive Implementation Plan for Option 3: Hybrid Faction Membership

### Overview
Implement a hybrid approach that adds a `primary_faction_id` field to characters while maintaining the existing CharacterFaction join table system. This provides easy client access for primary membership while preserving flexibility for complex faction relationships.

### Phase 1: Database Schema Changes (45 min)

#### 1.1 Create Migration for Primary Faction Field
- Add `primary_faction_id` field to characters table
- Add foreign key constraint to factions table
- Add index for performance
- Make field optional (nullable)

#### 1.2 Update Character Schema
- Add `belongs_to :primary_faction, Faction` relationship
- Update changeset to handle primary_faction_id
- Add validation that primary_faction exists when provided

### Phase 2: Business Logic Implementation (90 min)

#### 2.1 Primary Faction Sync Logic
- Create function to sync primary faction with CharacterFaction relationships
- Add logic to automatically create CharacterFaction entry when primary_faction_id is set
- Add logic to handle primary faction removal:
  * Set primary_faction_id = null
  * Update existing CharacterFaction relationship_type from "primary_member" to "member"
  * **DO NOT delete the CharacterFaction record** - preserve the relationship
- Ensure primary faction is marked with special relationship_type (e.g., "primary_member")

#### 2.2 Character Context Updates
- Update character creation to handle primary faction assignment
- Update character updates to sync primary faction changes
- Add helper functions for primary faction management
- Add function to get character with all faction relationships

#### 2.3 Faction Management Functions
- `set_primary_faction(character, faction, role \ "member")` - creates/updates CharacterFaction with "primary_member" type
- `remove_primary_faction(character)` - sets primary_faction_id to null, downgrades relationship_type to "member"
- `promote_to_primary_faction(character, faction_id)` - promotes existing relationship to primary
- `get_character_faction_summary(character)`

### Phase 3: API Endpoint Updates (45 min)

#### 3.1 Character Endpoints Enhancement
- Update character show/index to include primary_faction preload
- Update character creation endpoint to accept primary_faction_id
- Update character update endpoint to handle primary faction changes
- Ensure faction relationship changes sync with primary faction
- Handle primary_faction_id: null to remove primary faction (preserving CharacterFaction relationship)

#### 3.2 Optional Convenience Endpoint
- `GET /characters/:id/faction-summary` - Get complete faction relationship summary (if needed for complex UI scenarios)

### Phase 4: Response Format Enhancement (30 min)

#### 4.1 Character JSON Response Updates
- Include primary_faction in character responses
- Add faction_relationships array for complete relationship data
- Ensure backward compatibility

#### 4.2 Response Format Example
```json
{
  "character": {
    "id": "uuid",
    "name": "Character Name",
    "primary_faction": {
      "id": "faction-uuid",
      "name": "Faction Name",
      "role": "member"
    },
    "faction_relationships": [
      {
        "faction": {...},
        "relationship_type": "primary_member",
        "description": "Active member",
        "strength": 8,
        "is_active": true
      },
      {
        "faction": {...},
        "relationship_type": "ally",
        "description": "Allied faction",
        "strength": 6,
        "is_active": true
      }
    ]
  }
}
```

### Phase 5: Testing Strategy (75 min)

#### 5.1 Unit Tests
- Test primary faction assignment/removal via character updates
- Test sync logic between primary faction and relationships
- **Test that removing primary faction preserves CharacterFaction relationship**
- Test edge cases (faction deletion, character updates)
- Test helper functions

#### 5.2 Integration Tests
- Test complete character creation with primary faction
- Test faction relationship changes
- Test character update endpoint with primary_faction_id changes
- **Test primary faction removal maintains relationship data**
- Test edge cases and error handling

#### 5.3 Performance Tests
- Test query performance with primary faction preloads
- Verify index effectiveness
- Test bulk operations

### Phase 6: Documentation Updates (30 min)

#### 6.1 API Documentation
- Update Swagger specs for character endpoints
- Document primary_faction_id field in character schema
- Add examples showing primary faction management via character updates
- **Document that removing primary faction preserves relationship data**

#### 6.2 Developer Documentation
- Document sync logic and business rules
- **Clarify primary faction removal behavior (preserves CharacterFaction)**
- Add examples of common usage patterns
- Document helper functions and their usage

### Phase 7: Final Integration & Validation (30 min)

#### 7.1 End-to-End Testing
- Test complete user workflows
- Verify all acceptance criteria are met
- Performance validation

#### 7.2 Code Review & Cleanup
- Self-review implementation against acceptance criteria
- Ensure consistent code style and patterns
- Verify all edge cases are handled
- Final documentation updates

### Success Criteria

1. ✅ Characters can have a primary faction with direct field access
2. ✅ Existing CharacterFaction relationships remain fully functional
3. ✅ Primary faction stays synced with relationship table
4. ✅ APIs provide easy access to primary faction info via existing character endpoints
5. ✅ Complex faction relationships still supported via existing system
6. ✅ No breaking changes to existing API consumers
7. ✅ All tests pass including new hybrid functionality tests
8. ✅ Performance remains acceptable with new queries
9. ✅ All acceptance criteria from original task are satisfied
10. ✅ Primary faction management works seamlessly through character CRUD operations
11. ✅ **Removing primary faction preserves relationship data in CharacterFaction table**

### Business Logic Examples

```elixir
# Setting primary faction
set_primary_faction(character, faction)
# -> Sets character.primary_faction_id = faction.id
# -> Creates/updates CharacterFaction with relationship_type: "primary_member"

# Removing primary faction  
remove_primary_faction(character)
# -> Sets character.primary_faction_id = null
# -> Updates CharacterFaction relationship_type: "primary_member" -> "member"
# -> PRESERVES the CharacterFaction record
```

### API Usage Examples

```json
// Create character with primary faction
POST /characters
{
  "name": "Hero",
  "class": "Fighter", 
  "level": 1,
  "primary_faction_id": "faction-uuid"
}

// Update primary faction
PUT /characters/:id
{
  "primary_faction_id": "new-faction-uuid"
}

// Remove primary faction (preserves relationship)
PUT /characters/:id
{
  "primary_faction_id": null
}
```

### Risk Mitigation

- **Data Sync Issues**: Implement comprehensive validation and error handling
- **Performance Impact**: Add appropriate indexes and optimize queries
- **API Consistency**: Maintain backward compatibility and consistent patterns
- **Complex Edge Cases**: Thorough testing of faction deletion, character updates, etc.
- **Relationship Preservation**: Ensure removing primary faction preserves historical relationship data

### Estimated Timeline: ~4.5 hours total development time

This hybrid approach provides the best balance between ease of use and flexibility while maintaining the robustness of your existing faction relationship system and preserving relationship history.
<!-- SECTION:PLAN:END -->
