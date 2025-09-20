---
id: task-016
title: Implement faction note tree endpoint
status: To Do
assignee: []
created_date: '2025-09-20 15:21'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build /tree endpoint for Factions to fetch hierarchical child note structures using the new polymorphic parent relationships. This enables frontend components to display note trees attached to specific factions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Create faction note tree function in Notes context
- [ ] #2 Add tree endpoint to FactionController for GET .../factions/:id/notes/tree
- [ ] #3 Update router configuration for faction tree route
- [ ] #4 Add Swagger documentation for faction note tree endpoint
- [ ] #5 Create comprehensive tests for faction tree endpoint and context function
- [ ] #6 Ensure proper authentication and game scoping
- [ ] #7 Support both polymorphic parents (with parent_type) and traditional note hierarchies
<!-- AC:END -->
