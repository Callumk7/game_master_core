---
id: task-015
title: Implement location note tree endpoint
status: To Do
assignee: []
created_date: '2025-09-20 15:21'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build /tree endpoint for Locations to fetch hierarchical child note structures using the new polymorphic parent relationships. This enables frontend components to display note trees attached to specific locations.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Create location note tree function in Notes context
- [ ] #2 Add tree endpoint to LocationController for GET .../locations/:id/notes/tree
- [ ] #3 Update router configuration for location tree route
- [ ] #4 Add Swagger documentation for location note tree endpoint
- [ ] #5 Create comprehensive tests for location tree endpoint and context function
- [ ] #6 Ensure proper authentication and game scoping
- [ ] #7 Support both polymorphic parents (with parent_type) and traditional note hierarchies
<!-- AC:END -->
