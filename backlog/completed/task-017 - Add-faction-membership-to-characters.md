---
id: task-017
title: Add faction membership to characters
status: Done
assignee:
  - '@claude'
created_date: '2025-09-20 17:49'
updated_date: '2025-09-24 12:00'
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

### Key Principles
- **Minimal API Changes**: Only touch specific character endpoints, not bulk operations
- **Use Existing Endpoints**: Leverage existing faction endpoints instead of creating new ones
- **Simple Enhancement**: Add primary faction info only where it makes sense
- **Preserve relationship_type**: Never override user-defined relationship types - primary status is inferred from primary_faction_id field

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
  * **PRESERVE the CharacterFaction record and its relationship_type** - do not modify user-defined relationship types
  * **DO NOT delete the CharacterFaction record** - preserve the relationship
- **Never set or modify relationship_type** - this is user-controlled for describing roles/relationships

#### 2.2 Character Context Updates
- Update character creation to handle primary faction assignment
- Update character updates to sync primary faction changes
- Add helper functions for primary faction management

#### 2.3 Faction Management Functions
- `set_primary_faction(character, faction_id)` - creates CharacterFaction with default/empty relationship_type if none exists
- `remove_primary_faction(character)` - sets primary_faction_id to null, preserves CharacterFaction record unchanged
- `promote_to_primary_faction(character, faction_id)` - promotes existing relationship to primary without changing its relationship_type

### Phase 3: API Endpoint Updates (30 min)

#### 3.1 Character Show Endpoint Only
- Update character show endpoint to include primary_faction preload
- **DO NOT change index/list endpoints** - bulk operations don't need primary faction details
- Update character create/update endpoints to handle primary_faction_id changes
- Handle primary_faction_id: null to remove primary faction (preserving CharacterFaction relationship)

#### 3.2 No New Endpoints Needed
- Use existing faction endpoints for faction details
- Use existing character links endpoint for complete relationship data
- **Remove faction-summary endpoint** - not needed

### Phase 4: Response Format Enhancement (20 min)

#### 4.1 Character JSON Response Updates (Show Only)
- Include primary_faction_id in character responses
- Add primary_faction details if preloaded (show endpoint only)
- **Do NOT change index/list responses** - keep them lightweight
- Ensure backward compatibility

#### 4.2 Response Format Example
```json
{
  "character": {
    "id": "uuid",
    "name": "Character Name",
    "primary_faction_id": "faction-uuid",
    "primary_faction": {
      "id": "faction-uuid",
      "name": "Faction Name"
    },
    // ... other character fields
  }
}
```

### Phase 5: Testing Strategy (60 min)

#### 5.1 Unit Tests
- Test primary faction assignment/removal via character updates
- Test sync logic between primary faction and relationships
- **Test that removing primary faction preserves CharacterFaction relationship unchanged**
- **Test that relationship_type is never modified by primary faction operations**
- Test helper functions

#### 5.2 Integration Tests
- Test character creation with primary faction
- Test character update endpoint with primary_faction_id changes
- **Test primary faction removal maintains relationship data with original relationship_type**
- Test show endpoint includes primary faction data
- Test edge cases and error handling

#### 5.3 Performance Tests
- Test query performance with primary faction preloads (show endpoint only)
- Verify index effectiveness

### Phase 6: Documentation Updates (20 min)

#### 6.1 API Documentation
- Update Swagger specs for character show/create/update endpoints
- Document primary_faction_id field in character schema
- Add examples showing primary faction management via character updates
- **Document that primary faction operations preserve relationship_type**
- **Document that removing primary faction preserves relationship data unchanged**

#### 6.2 Developer Documentation
- Document sync logic and business rules
- **Clarify that relationship_type is never modified - only user-controlled**
- **Clarify primary faction removal behavior (preserves CharacterFaction completely unchanged)**
- Add examples of common usage patterns
- Document helper functions and their usage

### Phase 7: Final Integration & Validation (20 min)

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
4. ✅ Character show endpoint provides primary faction info
5. ✅ Complex faction relationships still supported via existing system
6. ✅ No breaking changes to existing API consumers
7. ✅ All tests pass including new hybrid functionality tests
8. ✅ Performance remains acceptable (only show endpoint affected)
9. ✅ All acceptance criteria from original task are satisfied
10. ✅ Primary faction management works seamlessly through character CRUD operations
11. ✅ **Removing primary faction preserves relationship data completely unchanged**
12. ✅ **Bulk operations (index/list) remain lightweight and unchanged**
13. ✅ **relationship_type field is never modified by primary faction operations**

### Business Logic Examples

```elixir
# Setting primary faction
set_primary_faction(character, faction_id)
# -> Sets character.primary_faction_id = faction_id
# -> Creates CharacterFaction with default relationship_type if none exists
# -> NEVER modifies existing relationship_type

# Removing primary faction  
remove_primary_faction(character)
# -> Sets character.primary_faction_id = null
# -> PRESERVES the CharacterFaction record completely unchanged
# -> relationship_type remains exactly as user set it
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

// Remove primary faction (preserves relationship completely)
PUT /characters/:id
{
  "primary_faction_id": null
}

// Show character (includes primary faction)
GET /characters/:id
// Returns character with primary_faction_id and primary_faction details

// List characters (lightweight, no primary faction details)
GET /characters
// Returns characters with primary_faction_id only, no preloaded details
```

### Risk Mitigation

- **Data Sync Issues**: Implement comprehensive validation and error handling
- **Performance Impact**: Only affect show endpoint, keep bulk operations lightweight
- **API Consistency**: Maintain backward compatibility and consistent patterns
- **Complex Edge Cases**: Thorough testing of faction deletion, character updates, etc.
- **Relationship Preservation**: Ensure removing primary faction preserves historical relationship data completely unchanged
- **relationship_type Integrity**: Never modify user-defined relationship types

### Estimated Timeline: ~4 hours total development time

This simplified hybrid approach provides the primary faction functionality while keeping the API minimal, leveraging existing endpoints, and preserving complete user control over relationship_type descriptions.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Successfully implemented faction membership for characters with the following features:

## Completed Implementation

✅ **Database Schema**: Added  (optional foreign key) and  (optional string) fields to characters table
✅ **Migration**: Created migration with proper foreign key constraints and indexing
✅ **Schema Updates**: Updated Character schema with new fields and belongs_to relationship to Faction
✅ **Validation**: Implemented validation requiring  when  is present
✅ **API Endpoints**: Character create/update endpoints now handle faction fields seamlessly
✅ **JSON Response**: Updated character JSON responses to include faction membership fields
✅ **Swagger Documentation**: Updated all character-related schemas and examples in Swagger
✅ **Comprehensive Testing**: Added extensive tests for both context layer and controller layer

## Key Features

- Optional faction membership - characters can exist without any faction affiliation
- Role-based membership - when a character belongs to a faction, they must have a role
- Foreign key integrity - prevents invalid faction references
- Backward compatibility - existing characters continue to work without changes
- Full API coverage - create, read, update operations all support faction fields
- Validation enforcement - prevents incomplete faction setup (faction without role)

## Technical Details

- Used  and  field names as specified in acceptance criteria
- Added foreign key constraint with  to handle faction deletion gracefully  
- Validation triggers only when faction is specified (not when only role is provided)
- All tests passing with comprehensive coverage of edge cases
- Swagger documentation updated with examples and proper field descriptions

The implementation successfully meets all acceptance criteria and provides a solid foundation for character-faction relationships.
<!-- SECTION:NOTES:END -->
