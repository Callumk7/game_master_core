---
id: task-024
title: Implement PUT endpoints for editing link relationships and metadata
status: To Do
assignee: []
created_date: '2025-09-30 10:19'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add missing PUT/PATCH functionality to allow editing of existing link relationships between entities. Currently users can create and delete links, but cannot modify link properties, metadata, or relationship details after creation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All entity controllers (Note, Character, Faction, Location, Quest) have PUT /links/:entity_type/:entity_id endpoints
- [ ] #2 Link metadata can be updated via PUT requests with proper validation
- [ ] #3 API supports partial updates (PATCH-like behavior) for link properties
- [ ] #4 Proper error handling for invalid entity types/IDs in PUT requests
- [ ] #5 Update operations respect game scope and user permissions
- [ ] #6 Swagger documentation updated for new PUT endpoints
- [ ] #7 Integration tests verify PUT functionality across all entity types
<!-- AC:END -->
