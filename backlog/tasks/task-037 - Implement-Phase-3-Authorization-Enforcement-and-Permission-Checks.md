---
id: task-037
title: 'Implement Phase 3: Authorization Enforcement and Permission Checks'
status: To Do
assignee: []
created_date: '2025-10-31 16:38'
labels:
  - backend
  - authorization
  - breaking-change
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Complete the authorization system by enforcing permission checks throughout the application.

**Context - Phases 1 & 2 Completed (PR #2):**
- Database schema updated with roles (admin/game_master/member), entity visibility (private/viewable/editable), and entity_shares table with cascade delete triggers
- Authorization module created with game-level RBAC and entity-level ACL functions
- Scope module tracks user roles
- All infrastructure in place but NOT enforced - current behavior unchanged

**Phase 3 Goal:**
Enforce authorization checks in context functions and API endpoints, ensuring users can only access/modify entities according to their permissions.

**Breaking Changes:**
This will introduce breaking changes for the client app:
- Entity lists will filter based on visibility and shares
- CRUD operations will return {:error, :unauthorized} for unpermitted actions
- API responses will include visibility and permission metadata

**Recommended Approach:**
Use backward-compatible defaults (all entities editable, auto-shared) to avoid breaking existing functionality while enabling new permission features.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Update all entity context CRUD functions (Characters, Factions, Locations, Quests, Notes) to enforce authorization checks using Authorization.can_access_entity?/3
- [ ] #2 Add API endpoints for sharing management (share/unshare entities with users)
- [ ] #3 Add API endpoints for role management (assign/change member roles in games)
- [ ] #4 Add API endpoints for visibility management (change entity visibility)
- [ ] #5 Update API responses to include visibility field and user_permissions metadata
- [ ] #6 Comprehensive test suite review and update - ensure authorization tests cover all permission scenarios (role-based, visibility-based, share-based)
- [ ] #7 Add integration tests for unauthorized access attempts returning proper error responses
- [ ] #8 Update API documentation (Swagger) with new endpoints and permission requirements
- [ ] #9 Ensure backward compatibility with default visibility settings and auto-sharing behavior
<!-- AC:END -->
