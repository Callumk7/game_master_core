---
id: task-006
title: Refactor link retrieval endpoints
status: Done
assignee: []
created_date: '2025-09-19 09:49'
updated_date: '2025-09-19 10:58'
labels:
  - backend
  - api
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Overhaul GET .../\{id\}/links endpoints to query multiple join tables and merge results into consistent response format
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Query all relevant join tables for given entity
- [x] #2 Merge results from multiple tables into single consistent list
- [x] #3 Ensure uniform response structure for front-end consumption
- [x] #4 Optimize query performance across multiple tables
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Task completed as part of task-002 implementation.

### Implementation Summary

**Multiple join table queries**: All 5 service modules now query relevant join tables through the Links.links_for/1 function which handles querying across all 15 join tables for any given entity.

**Result merging**: The Links module consolidates results from multiple join tables into a consistent structure organized by entity type:

```elixir
%{
  notes: [...],
  characters: [...],
  factions: [...],
  locations: [...],
  quests: [...]
}
```

**Uniform response structure**: All controllers use consistent `render(conn, :links, ...)` calls that provide:
- Source entity information
- Linked entities grouped by type
- Full relationship metadata (relationship_type, description, strength, is_active, metadata)

**Query optimization**: Links module uses efficient Ecto queries with proper joins and associations to minimize database hits while fetching complete relationship data.

**Enhanced API responses**: Updated Swagger schemas (LinkedCharacter, LinkedFaction, etc.) provide structured responses that include both entity data and relationship metadata for front-end consumption.

**Existing endpoints**: All GET .../{id}/links endpoints already implemented and working correctly with the new metadata-rich response format.

**Testing**: All 693 tests pass, confirming link retrieval endpoints work correctly across all entity types.
<!-- SECTION:NOTES:END -->
