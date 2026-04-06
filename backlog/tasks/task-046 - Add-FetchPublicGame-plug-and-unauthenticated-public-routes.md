---
id: TASK-046
title: Add FetchPublicGame plug and unauthenticated public routes
status: To Do
assignee: []
created_date: '2026-04-06 15:43'
labels:
  - public-entities
dependencies:
  - TASK-045
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The public API endpoints must be reachable without an auth token, but must still resolve and validate the target game. A new plug handles game resolution for these routes: it reads :game_id from params, delegates to the Public context, and either assigns the game to the conn or halts with a 404. The router wires this plug into a new unauthenticated scope serving the public entity routes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A new plug module GameMasterCoreWeb.Plugs.FetchPublicGame exists
- [ ] #2 The plug reads game_id from conn.params, calls GameMasterCore.Public.fetch_public_game/1, assigns the result as :game on the conn, and calls next when found
- [ ] #3 The plug halts the connection and returns a JSON 404 response when the game is not found or is not public
- [ ] #4 A new router scope is added with no authentication pipeline (no :require_session_auth, no :assign_current_game)
- [ ] #5 The new scope applies :session_api and :fetch_public_game pipelines/plugs only
- [ ] #6 GET routes exist under /api/public/games/:game_id/ for: characters, factions, locations, notes, quests
- [ ] #7 No POST, PATCH, PUT, or DELETE routes exist in the public scope
<!-- AC:END -->
