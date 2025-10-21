---
id: task-005
title: Refactor link creation endpoints
status: Done
assignee: []
created_date: '2025-09-19 09:49'
updated_date: '2025-09-19 10:57'
labels:
  - backend
  - api
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Overhaul POST .../\{id\}/links endpoints to handle metadata and determine correct join tables based on entity types
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Modify POST endpoints to accept metadata in request body
- [x] #2 Implement service logic to determine correct join table based on source and target entity types
- [x] #3 Insert new records into specific tables with provided metadata
- [x] #4 Add validation for metadata fields and entity type combinations
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Task completed as part of task-002 implementation.

### Implementation Summary

**POST endpoints refactored**: All 5 controllers (character, faction, location, quest, note) now accept metadata in request body through consistent parameter extraction:

```elixir
metadata_attrs = %{
  relationship_type: Map.get(params, "relationship_type"),
  description: Map.get(params, "description"),
  strength: Map.get(params, "strength"),
  is_active: Map.get(params, "is_active"),
  metadata: Map.get(params, "metadata")
}
```

**Service logic implemented**: All service modules (Characters, Factions, Locations, Quests, Notes) determine correct join tables based on entity types and pass metadata through the Links module which handles the specific table selection.

**Database insertion**: Links module creates records in correct join tables (15 total) with provided metadata merged into changeset attributes.

**Validation added**: Metadata fields validated in join table schemas:
- `strength`: integer range 1-10 validation
- All fields properly cast in changesets
- Entity type validation through existing validate_entity_type/1 functions

**Swagger documentation**: Updated API documentation to reflect metadata fields in request bodies with proper validation and examples.

**Testing**: All 693 tests pass, confirming endpoints work correctly with metadata.
<!-- SECTION:NOTES:END -->
