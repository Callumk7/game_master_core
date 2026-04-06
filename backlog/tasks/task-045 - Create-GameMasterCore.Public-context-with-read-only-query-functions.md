---
id: TASK-045
title: Create GameMasterCore.Public context with read-only query functions
status: To Do
assignee: []
created_date: '2026-04-06 15:43'
labels:
  - public-entities
dependencies:
  - TASK-042
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A dedicated, isolated context is needed to serve public data without touching or weakening the existing auth-scoped contexts. GameMasterCore.Public will be the single source of truth for all unauthenticated reads. It operates on a game struct directly (no Scope) and applies a strict double filter: the entity must be in the given game and must itself be marked is_public = true.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A new GameMasterCore.Public module exists at lib/game_master_core/public.ex (or equivalent namespace)
- [ ] #2 fetch_public_game/1 accepts a game ID, returns {:ok, game} if the game exists and is_public = true, {:error, :not_found} otherwise
- [ ] #3 list_public_characters/1, list_public_factions/1, list_public_locations/1, list_public_notes/1, list_public_quests/1 each accept a game struct and return only entities where game_id = game.id AND is_public = true
- [ ] #4 fetch_public_character/2, fetch_public_faction/2, fetch_public_location/2, fetch_public_note/2, fetch_public_quest/2 accept a game struct and entity ID, returning {:ok, entity} or {:error, :not_found} with the same visibility filter applied
- [ ] #5 No Scope struct is used anywhere in this module
- [ ] #6 The module has no dependency on existing auth-scoped contexts (Games, Characters, etc.)
- [ ] #7 Unit tests verify that entities with is_public = false are excluded and that entities belonging to a different game are excluded
<!-- AC:END -->
