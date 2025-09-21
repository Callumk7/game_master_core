---
id: task-014
title: Implement quest note tree endpoint
status: To Do
assignee: []
created_date: '2025-09-20 15:21'
updated_date: '2025-09-21 09:00'
labels: []
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build /tree endpoint for Quests to fetch hierarchical child note structures using the new polymorphic parent relationships. This enables frontend components to display note trees attached to specific quests.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Create quest note tree function in Notes context
- [ ] #2 Add tree endpoint to QuestController for GET .../quests/:id/notes/tree
- [ ] #3 Update router configuration for quest tree route
- [ ] #4 Add Swagger documentation for quest note tree endpoint
- [ ] #5 Create comprehensive tests for quest tree endpoint and context function
- [ ] #6 Ensure proper authentication and game scoping
- [ ] #7 Support both polymorphic parents (with parent_type) and traditional note hierarchies
<!-- AC:END -->
