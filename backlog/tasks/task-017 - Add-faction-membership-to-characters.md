---
id: task-017
title: Add faction membership to characters
status: To Do
assignee: []
created_date: '2025-09-20 17:49'
updated_date: '2025-09-21 09:00'
labels:
  - backend
  - database
  - api
  - swagger
dependencies: []
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow characters to specify which faction they belong to and their role within that faction. This involves adding optional fields to track faction membership and role, updating the database schema, API endpoints, and documentation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Add member_of_faction_id field to character schema (optional)
- [ ] #2 Add faction_role field to character schema (optional)
- [ ] #3 Update character creation/update API endpoints to handle faction fields
- [ ] #4 Add database migration for new character fields
- [ ] #5 Update swagger documentation to reflect new character fields
- [ ] #6 Write tests for character faction membership functionality
- [ ] #7 Ensure faction_role validation when member_of_faction_id is present
<!-- AC:END -->
