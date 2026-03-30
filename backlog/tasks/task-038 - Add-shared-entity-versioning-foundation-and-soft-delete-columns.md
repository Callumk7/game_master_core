---
id: TASK-038
title: Add shared entity versioning foundation and soft-delete columns
status: To Do
assignee: []
created_date: '2026-03-30 13:45'
labels:
  - backend
  - versioning
  - database
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Introduce the database and shared-domain foundation for version history across characters, factions, notes, locations, and quests. This task adds the shared entity_versions store, adds current_revision and deleted_at to the five entity tables, and backfills an initial baseline version for existing rows so all current entities have history from day one.

Testing Strategy:
- Add migration or integration coverage verifying the new columns exist and default correctly.
- Add data migration coverage confirming an existing entity gets one baseline version row with the expected snapshot shape.
- Add unit tests for the shared snapshot builder to verify each entity type serializes only the intended direct fields.

Defaults Locked In:
- v1 versions direct entity fields only, not links, images, or objectives.
- No controller or route changes are introduced in this task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A new shared version table exists for entity snapshots with fields for entity_type, entity_id, game_id, actor_id, revision, action, snapshot, and timestamps
- [ ] #2 characters, factions, notes, locations, and quests each have current_revision and deleted_at columns
- [ ] #3 Existing rows in all five tables are backfilled with an initial baseline version entry
- [ ] #4 Unique and supporting indexes exist to support per-entity revision history reads and prevent duplicate revisions
- [ ] #5 A shared Elixir versioning module exists for building and storing field-level snapshots for the five supported entity types
- [ ] #6 No controller or route changes are introduced in this task
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Migrations run cleanly on an empty database and on a populated local database
- [ ] #2 Baseline snapshots are created for pre-existing entities without duplicating revisions
- [ ] #3 Shared snapshot builder behavior is covered by automated tests
- [ ] #4 mix precommit passes
<!-- DOD:END -->
