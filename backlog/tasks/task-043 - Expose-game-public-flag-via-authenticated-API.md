---
id: TASK-043
title: Expose game public flag via authenticated API
status: To Do
assignee: []
created_date: '2026-04-06 15:42'
labels:
  - public-entities
dependencies:
  - TASK-042
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Game owners need the ability to mark their game as public or private through the existing authenticated game update endpoint. This controls the master visibility switch introduced in task-042. The flag must be accepted in update requests, persisted, and returned in API responses so clients can read and display the current visibility state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Games context update_game/3 accepts is_public in the attrs map and persists it
- [ ] #2 The authenticated PATCH /api/games/:game_id endpoint accepts is_public in the request body
- [ ] #3 Only the game owner can change is_public (existing ownership/Bodyguard check enforces this — no new auth logic required)
- [ ] #4 Game JSON responses include the is_public field
- [ ] #5 A non-owner attempting to set is_public receives a 403 response
- [ ] #6 Controller and/or context tests cover setting is_public to true and false
<!-- AC:END -->
