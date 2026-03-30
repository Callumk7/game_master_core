---
id: TASK-040
title: 'Expose version history, deleted entities, and restore endpoints in the API'
status: To Do
assignee: []
created_date: '2026-03-30 13:46'
labels:
  - backend
  - api
  - versioning
  - swagger
dependencies:
  - TASK-039
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the game-scoped JSON API endpoints needed for clients to view history, browse deleted entities, inspect a specific revision, and restore an entity to a previous revision. This task also updates response shapes and Swagger docs to expose current_revision and version metadata.

Implementation Notes:
- New routes should live in the existing authenticated JSON game scope under scope "/api", GameMasterCoreWeb with pipe_through [:session_api, :require_session_auth, :assign_current_game] because these endpoints are game-scoped API routes and require current_scope.game.

Testing Strategy:
- Add controller tests for all new endpoints across at least one entity type, plus shared behavior coverage for conflict handling.
- Add response-shape tests verifying current_revision, version metadata, snapshot payloads, and 409 responses.
- Add Swagger-oriented assertions where the codebase already validates documented payload structures.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each versioned entity resource exposes endpoints for deleted-entity listing, version listing, version detail, and restore
- [ ] #2 Existing update and delete endpoints accept current_revision and return 409 Conflict for stale writes
- [ ] #3 Entity JSON responses include current_revision
- [ ] #4 Version list responses return revision metadata only and version detail returns the stored snapshot
- [ ] #5 Restore endpoints accept target_revision plus current_revision
- [ ] #6 Swagger documentation is updated for all new endpoints and changed request and response contracts
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 New routes live in the existing authenticated JSON game scope and use current_scope.game
- [ ] #2 Clients can fetch deleted entities, inspect version history, and restore a version entirely through the API
- [ ] #3 Stale write protection is enforced at the HTTP boundary
- [ ] #4 Swagger matches actual controller behavior
- [ ] #5 mix precommit passes
<!-- DOD:END -->
