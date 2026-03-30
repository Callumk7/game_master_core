---
id: TASK-041
title: Hide soft-deleted entities from active reads and add regression coverage
status: To Do
assignee: []
created_date: '2026-03-30 13:46'
labels:
  - backend
  - api
  - versioning
  - regression
dependencies:
  - TASK-039
  - TASK-040
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update read-side behavior so soft-deleted entities disappear from normal application flows while their data remains restorable. This includes lists, trees, search, pinned views, links, faction-member queries, and image endpoints that depend on active entities.

Testing Strategy:
- Add regression tests for search, pinned, tree, and links behavior with deleted versus restored entities.
- Add controller or context tests for image endpoints proving hidden-on-delete and visible-on-restore behavior.
- Add regression tests for faction member counts and lists when characters are soft-deleted and restored.

Defaults Locked In:
- Soft-deleted entities are hidden from normal reads and discoverable only through deleted and history flows.
- Restoring an entity should make it visible again in all affected read paths without manual repair.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Standard entity index and show flows exclude soft-deleted rows unless explicitly using deleted or history endpoints
- [ ] #2 Search, pinned, and tree endpoints exclude soft-deleted entities
- [ ] #3 Link payloads do not expose linked entities that are currently soft-deleted
- [ ] #4 Faction member lists and counts exclude deleted characters
- [ ] #5 Image listing, primary-image lookup, stats, and game-wide image endpoints exclude images for soft-deleted entities
- [ ] #6 Restoring an entity makes it visible again in all affected read paths without manual repair
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 No normal read path leaks soft-deleted entities
- [ ] #2 Restored entities reappear cleanly in all relevant read paths
- [ ] #3 Read-side regressions are covered by automated tests rather than manual verification only
- [ ] #4 mix precommit passes
<!-- DOD:END -->
