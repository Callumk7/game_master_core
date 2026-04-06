---
id: TASK-044
title: Expose entity public flag via authenticated API
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
Entity creators need to mark individual characters, factions, locations, notes, and quests as public or private through the existing authenticated create and update endpoints. This per-entity flag works in conjunction with the game-level flag introduced in task-042. The flag must be accepted on writes, persisted, and surfaced in API responses.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Create and update endpoints for characters, factions, locations, notes, and quests each accept is_public in the request body
- [ ] #2 Each entity's changeset casts is_public (building on schema changes from task-042)
- [ ] #3 is_public is returned in the JSON response for each entity type
- [ ] #4 Existing Bodyguard ownership checks already gate these endpoints — no additional auth logic is required
- [ ] #5 Controller and/or context tests for at least one entity type cover creating and updating is_public
<!-- AC:END -->
