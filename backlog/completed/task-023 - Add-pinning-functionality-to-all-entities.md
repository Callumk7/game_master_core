---
id: task-023
title: Add pinning functionality to all entities
status: Done
assignee:
  - '@claude'
created_date: '2025-09-25 11:33'
updated_date: '2025-09-25 13:33'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement pinning functionality that allows users to pin/unpin entities (characters, notes, factions, locations, quests) within their games. Each entity should have a pinned boolean column, and the API should support both individual entity pinning and retrieving all pinned entities across types.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Database migration adds pinned boolean column (default false) to all entity tables with proper indexes
- [x] #2 All Ecto schemas updated to include pinned field in schema and changesets
- [x] #3 Individual entity controllers support PUT /{entity}/{id}/pin and PUT /{entity}/{id}/unpin endpoints
- [x] #4 New PinnedController with GET /games/{game_id}/pinned endpoint returns all pinned entities
- [x] #5 All JSON helpers updated to include pinned field in responses
- [x] #6 Context modules have pin/unpin functions with proper authorization
- [x] #7 Comprehensive tests for pinning functionality across all entities
- [x] #8 Swagger documentation updated for all new pinning endpoints
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Database Migration
   - Create migration to add pinned boolean column (default false) to all entity tables
   - Add proper indexes for efficient pinned entity queries
   - Target tables: characters, notes, factions, locations, quests

2. Schema Updates
   - Update all Ecto schemas to include pinned field
   - Update changesets to allow pinned field in cast operations
   - Ensure pinned field is properly validated if needed

3. Context Module Functions
   - Add pin/unpin functions to each context module (Characters, Notes, Factions, Locations, Quests)
   - Implement proper authorization checks using scoped queries
   - Add functions to list pinned entities per context

4. Individual Entity Controller Endpoints
   - Add PUT /{entity}/{id}/pin endpoints to all entity controllers
   - Add PUT /{entity}/{id}/unpin endpoints to all entity controllers
   - Follow existing controller patterns for authorization and error handling

5. Unified Pinned Controller
   - Create new PinnedController with GET /games/{game_id}/pinned endpoint
   - Implement logic to fetch all pinned entities across all entity types
   - Return structured response with entities grouped by type

6. JSON Response Updates
   - Update all JSON helper functions to include pinned field
   - Ensure pinned field appears in all entity JSON responses
   - Update existing JSON views to use updated helpers

7. Router Configuration
   - Add pinning routes to existing entity resource blocks
   - Add new pinned route at game level
   - Follow existing routing patterns and scoping

8. Comprehensive Testing
   - Write tests for all pin/unpin context functions
   - Write controller tests for all new endpoints
   - Write integration tests for the unified pinned endpoint
   - Test authorization and error handling scenarios

9. Swagger Documentation
   - Update swagger definitions for all entity schemas to include pinned field
   - Add swagger documentation for all new pinning endpoints
   - Update existing endpoint docs if needed
<!-- SECTION:PLAN:END -->
