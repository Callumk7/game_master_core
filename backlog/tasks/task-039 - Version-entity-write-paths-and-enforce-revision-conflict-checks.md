---
id: TASK-039
title: Version entity write paths and enforce revision conflict checks
status: To Do
assignee: []
created_date: '2026-03-30 13:45'
labels:
  - backend
  - versioning
  - data-integrity
dependencies:
  - TASK-038
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Integrate version creation and soft delete into the core entity write paths in Characters, Factions, Notes, Locations, and Quests. This task changes create, update, delete, and restore behavior so version rows are written transactionally and stale writes are rejected using current_revision.

Testing Strategy:
- Add context tests for each entity type covering create, update, soft delete, and restore.
- Add conflict-path tests proving stale current_revision values do not modify the live row or create history rows.
- Add transaction tests proving live-row changes and version inserts succeed or fail together.

Defaults Locked In:
- Links and images are preserved on soft delete.
- Restore reapplies only direct entity fields from the selected snapshot.
- Server-enforced revision checks are part of v1.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Create operations for the five entity types write revision 1 history rows with the appropriate action
- [ ] #2 Update operations require current_revision, reject stale requests with a conflict result, increment the live row revision, and write an updated snapshot
- [ ] #3 Delete operations become soft delete operations, require current_revision, set deleted_at, increment revision, and write a deleted snapshot
- [ ] #4 Restore domain functions exist for the five entity types and can reapply a target snapshot to the live row while clearing deleted_at
- [ ] #5 Restore operations require current_revision, increment revision, and write a restored snapshot
- [ ] #6 Links and images are preserved on soft delete and entity deletes no longer permanently remove them
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All five entity contexts use the shared versioning behavior consistently
- [ ] #2 Soft delete replaces permanent delete for the five versioned entities
- [ ] #3 Restore behavior is implemented at the context level and is not controller-only
- [ ] #4 Automated tests cover success and conflict cases for each operation family
- [ ] #5 mix precommit passes
<!-- DOD:END -->
