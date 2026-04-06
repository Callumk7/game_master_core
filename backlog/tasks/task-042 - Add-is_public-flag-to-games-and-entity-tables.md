---
id: TASK-042
title: Add is_public flag to games and entity tables
status: In Progress
assignee:
  - '@claude'
created_date: '2026-04-06 15:41'
updated_date: '2026-04-06 15:50'
labels:
  - public-entities
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The public entity feature requires a visibility flag on the games table and on each entity table (characters, factions, locations, notes, quests). The games flag acts as a master switch — an entity is only publicly accessible if its game is also public. This task lays the database and schema foundation that all subsequent public-entity work depends on.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A single migration adds is_public boolean NOT NULL DEFAULT false to games, characters, factions, locations, notes, and quests tables
- [x] #2 Each corresponding Ecto schema module declares the is_public field as :boolean
- [x] #3 Each entity changeset casts is_public so the field can be set via changeset pipelines
- [x] #4 Migration is reversible (down removes the columns)
- [ ] #5 Existing tests continue to pass with no changes required
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read all entity schemas to understand current fields and changeset patterns
2. Write single migration adding is_public boolean NOT NULL DEFAULT false to all 6 tables
3. Add is_public field declaration to each schema module
4. Add is_public to each changeset cast list
5. Compile to verify no errors
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Single migration adds is_public boolean NOT NULL DEFAULT false to games, characters, factions, locations, notes, quests tables with reversible up/down. Each schema module updated with field declaration and cast in changeset. Compiles cleanly. AC5 (existing tests pass) can only be verified once migration is run against the database.
<!-- SECTION:NOTES:END -->
