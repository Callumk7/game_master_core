---
id: task-031
title: Add endpoint to fetch all images for a game
status: Done
assignee:
  - '@claude'
created_date: '2025-10-08 12:54'
updated_date: '2025-10-08 13:06'
labels:
  - api
  - images
  - backend
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement a RESTful endpoint that retrieves all images across all entities within a specific game. This endpoint will provide game masters with a centralized view of all visual assets uploaded to their game, enabling better content management and overview capabilities.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Endpoint GET /api/games/{game_id}/images returns all images for the game
- [x] #2 Response includes image metadata (filename, alt_text, entity association)
- [x] #3 Images are ordered by creation date (newest first) with optional primary_first parameter
- [x] #4 Endpoint handles pagination with limit and offset query parameters
- [x] #5 Proper error handling for non-existent games and unauthorized access
- [x] #6 Comprehensive test coverage for happy path and edge cases
- [x] #7 Swagger documentation generated and updated
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add list_images_for_game function to Images context
2. Add game images route to router
3. Add game_images action to ImageController
4. Update swagger documentation
5. Write comprehensive tests for the new endpoint
6. Test manually and run lint/typecheck
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented game images endpoint at GET /api/games/{game_id}/images

Changes made:
- Added list_images_for_game/2 function to Images context with support for primary_first, limit, and offset options
- Added game_images route to router under game scope
- Added game_images/2 action to ImageController with robust parameter parsing
- Added game_images/1 render function to ImageJSON for consistent API responses
- Added comprehensive swagger documentation with proper parameter definitions
- Added full test coverage for both controller and context layers

Features:
- Pagination support via limit/offset query parameters
- Primary images first sorting via primary_first=true parameter
- Robust parameter parsing with graceful error handling
- Consistent JSON response format matching existing API patterns
- Proper authentication and game scoping
- Full swagger documentation for API consumers

All tests pass and precommit checks successful.
<!-- SECTION:NOTES:END -->
