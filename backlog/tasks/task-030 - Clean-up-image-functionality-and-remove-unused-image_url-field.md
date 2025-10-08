---
id: task-030
title: Clean up image functionality and remove unused image_url field
status: Done
assignee:
  - '@claude'
created_date: '2025-10-08 10:22'
updated_date: '2025-10-08 10:31'
labels:
  - cleanup
  - images
  - api
  - database
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Clean up leftover functionality from the old image system after implementing the new image upload system. Remove unused image_url field from characters and fix misleading swagger documentation that shows fields not actually returned by the API.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 image_url field completely removed from character database schema (migration created)
- [ ] #2 image_url field removed from character Ecto schema
- [ ] #3 image_url field removed from character JSON helpers and serialization
- [ ] #4 image_url field removed from admin forms and character creation/editing
- [ ] #5 image_url field removed from character tests and test fixtures
- [ ] #6 primary_image and images fields removed from swagger docs for all entities (characters, factions, locations, quests)
- [ ] #7 GET /games/:game_id/:entity_type/:entity_id/images/primary endpoint added to image controller
- [ ] #8 All existing tests pass after cleanup
- [ ] #9 No breaking changes to existing image API functionality
- [ ] #10 Documentation updated to clarify image data is fetched via separate image endpoints
<!-- AC:END -->
