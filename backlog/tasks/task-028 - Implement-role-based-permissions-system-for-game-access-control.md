---
id: task-028
title: Implement role-based permissions system for game access control
status: To Do
assignee: []
created_date: '2025-10-05 20:07'
updated_date: '2025-10-05 20:07'
labels:
  - backend
  - permissions
  - rbac
  - security
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Currently the app has basic binary membership (owner/member) where members have full access to all game entities. Need to implement a comprehensive role-based permission system to allow granular access control for viewing and editing game entities (characters, factions, locations, notes, quests).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Research and document current permission system limitations
- [ ] #2 Design role hierarchy and permission matrix
- [ ] #3 Update GameMembership schema to support new roles
- [ ] #4 Implement permission checking functions in Games context
- [ ] #5 Update all entity contexts with permission checks
- [ ] #6 Add permission middleware for API routes
- [ ] #7 Create role management interface for game owners
- [ ] #8 Add permission indicators in UI
- [ ] #9 Implement audit logging for permission changes
- [ ] #10 Update API documentation with new permission requirements
- [ ] #11 Add comprehensive test coverage for all permission scenarios
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Current System Analysis

### Current Authentication Flow
- Uses Phoenix phx.gen.auth with GameMasterCoreWeb.UserAuth
- Scope-based access using GameMasterCore.Accounts.Scope
- Game membership through GameMasterCore.Games.GameMembership

### Current Access Control (Binary Model)
- **Owner**: Full access (modify, delete, add/remove members)
- **Member**: Can access game and all entities (characters, factions, locations, notes, quests)
- **Non-member**: No access

### Key Functions (lib/game_master_core/games.ex:270-281)
- `can_modify_game?/2` - Only owners can modify
- `can_access_game?/2` - Owners and members can access

### Current GameMembership Schema
```elixir
role: :string, default: "member"
validate_inclusion(:role, ["member", "owner"])
```

## Proposed Role-Based Permission System

### 1. Enhanced Role Structure
```elixir
# Expand roles beyond just "member" and "owner"
roles = ["viewer", "player", "contributor", "moderator", "admin", "owner"]
```

### 2. Permission Matrix
```
                │ View │ Edit │ Create │ Delete │ Manage Members │
─────────────────┼──────┼──────┼────────┼────────┼───────────────│
viewer          │  ✓   │  ✗   │   ✗    │   ✗    │      ✗        │
player          │  ✓   │  ✗   │   ✗    │   ✗    │      ✗        │
contributor     │  ✓   │  ✓   │   ✓    │   ✗    │      ✗        │
moderator       │  ✓   │  ✓   │   ✓    │   ✓    │      ✗        │
admin           │  ✓   │  ✓   │   ✓    │   ✓    │      ✓        │
owner           │  ✓   │  ✓   │   ✓    │   ✓    │      ✓        │
```

### 3. Implementation Options

**Option A: Simple Role-Based (Recommended)**
- Extend current GameMembership.role field
- Add permission checking functions
- Minimal database changes

**Option B: Full RBAC with Permission Tables**
- Create permissions and role_permissions tables
- Maximum flexibility
- More complex implementation

**Option C: Hybrid Approach**
- Role-based for common scenarios
- Entity-specific permissions for edge cases

## Implementation Plan

### Phase 1: Core Permission Infrastructure (2-3 days)

#### 1.1 Update GameMembership Schema
- Add migration to support new roles
- Update validation to include new role types
- Ensure backward compatibility with existing data

#### 1.2 Create Permission Module
```elixir
defmodule GameMasterCore.Permissions do
  def can?(scope, action, resource)
  def has_role?(scope, role)
  def role_permissions(role)
end
```

#### 1.3 Update Games Context
- Replace binary permission checks with role-based checks
- Add new permission functions:
  - `can_view_game?/2`
  - `can_edit_game?/2`
  - `can_manage_members?/2`

### Phase 2: Entity-Level Permissions (3-4 days)

#### 2.1 Update Context Modules
- Characters context: Add role checks for CRUD operations
- Factions context: Add role checks for CRUD operations
- Locations context: Add role checks for CRUD operations
- Notes context: Add role checks for CRUD operations
- Quests context: Add role checks for CRUD operations

#### 2.2 Permission Middleware
```elixir
defmodule GameMasterCoreWeb.Permissions do
  def require_permission(conn, action, resource)
  def require_role(conn, role)
end
```

#### 2.3 Update Controllers
- Add permission checks to all controller actions
- Return appropriate error responses for unauthorized access
- Update API error handling

### Phase 3: UI and Management Features (2-3 days)

#### 3.1 Role Management Interface
- Admin interface for managing member roles
- Role assignment/modification functionality
- Permission overview for game owners

#### 3.2 Permission Indicators
- Show user roles in member lists
- Display permission status in UI
- Add permission-based feature toggling

#### 3.3 Audit Logging
- Log role changes
- Track permission modifications
- Security audit trail

### Phase 4: Testing and Documentation (2 days)

#### 4.1 Comprehensive Test Coverage
- Unit tests for permission functions
- Integration tests for controller actions
- Test all role combinations and scenarios

#### 4.2 API Documentation
- Update Swagger definitions
- Document permission requirements
- Add error response examples

## File Changes Required

### Database
- `priv/repo/migrations/add_new_roles_to_game_membership.exs`

### Core Modules
- `lib/game_master_core/permissions.ex` (new)
- `lib/game_master_core/games/game_membership.ex`
- `lib/game_master_core/games.ex`
- `lib/game_master_core/characters.ex`
- `lib/game_master_core/factions.ex`
- `lib/game_master_core/locations.ex`
- `lib/game_master_core/notes.ex`
- `lib/game_master_core/quests.ex`

### Web Layer
- `lib/game_master_core_web/permissions.ex` (new)
- All controller modules
- `lib/game_master_core_web/router.ex`

### Tests
- `test/game_master_core/permissions_test.exs` (new)
- Update all existing controller tests
- Add permission-specific test scenarios

## Backward Compatibility

- Existing "member" and "owner" roles remain functional
- Migration will not affect existing user access
- Gradual rollout possible with feature flags

## Security Considerations

- Default to most restrictive permissions
- Validate permissions on every request
- Audit trail for all permission changes
- Rate limiting for role modification requests

## Performance Considerations

- Cache permission checks where appropriate
- Index database queries for role lookups
- Minimize permission check overhead
- Consider permission preloading for batch operations
<!-- SECTION:PLAN:END -->
