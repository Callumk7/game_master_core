---
id: TASK-047
title: Implement public controller actions and integration tests
status: To Do
assignee: []
created_date: '2026-04-06 15:44'
labels:
  - public-entities
dependencies:
  - TASK-045
  - TASK-046
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The public routes introduced in task-046 need controller actions that call the Public context and render responses. This task also adds the integration test coverage to verify the full request path: correct entities are returned for public games, private entities are excluded, and requests for non-public games are rejected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Controller actions exist for each public route (characters, factions, locations, notes, quests) and call the corresponding GameMasterCore.Public list function
- [ ] #2 Each action renders a JSON list of entities using the existing JSON view/render conventions
- [ ] #3 Integration test: GET request to a public game entity route returns only entities where is_public = true
- [ ] #4 Integration test: entities where is_public = false are absent from the public list response even when the game is public
- [ ] #5 Integration test: GET request where the game is_public = false returns a 404 response
- [ ] #6 Integration test: GET request with a non-existent game_id returns a 404 response
- [ ] #7 No auth token is sent in the test requests for the public endpoints, confirming they are truly unauthenticated
<!-- AC:END -->
