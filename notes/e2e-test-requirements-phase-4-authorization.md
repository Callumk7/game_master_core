# E2E Test Requirements: Phase 4 Authorization System

**Document Version:** 1.0
**Date:** 2025-11-01
**Purpose:** Comprehensive test specification for Phase 4 authorization and permissions system

---

## Table of Contents

1. [Overview](#overview)
2. [Test User Setup](#test-user-setup)
3. [Game-Level Permission Tests](#game-level-permission-tests)
4. [Entity-Level Permission Tests](#entity-level-permission-tests)
5. [Entity Sharing Tests](#entity-sharing-tests)
6. [Permission Metadata Tests](#permission-metadata-tests)
7. [Edge Cases and Security Tests](#edge-cases-and-security-tests)
8. [Test Organization](#test-organization)

---

## Overview

### Authorization System Architecture

The system implements a **Hybrid RBAC + ACL** model:

**Layer 1: Role-Based Game Permissions**
- **Admin**: Full game management + all entity access
- **Game Master**: All entity access, no game/member management
- **Member**: Subject to entity-level permissions

**Layer 2: Entity-Level Access Control**
- **Visibility**: Global access level (private/viewable/editable)
- **Shares**: Explicit user permissions (editor/viewer/blocked)

### Resolution Order

1. Admin/Game Master role bypass (always allow)
2. Explicit entity shares (blocked/editor/viewer)
3. Entity ownership check
4. Global visibility setting

### Entities to Test

All tests must cover these entity types:
- Character
- Faction
- Location
- Quest
- Note

---

## Test User Setup

### Required Test Users

Create the following users for each test suite:

```elixir
# Game membership users
admin_user        # Role: admin
game_master_user  # Role: game_master
member_user_1     # Role: member (creator of test entities)
member_user_2     # Role: member (non-creator)
member_user_3     # Role: member (for share testing)

# Non-member user
non_member_user   # Not in the game at all
```

### Test Game Setup

```elixir
test_game = create_game(admin_user)
add_member(test_game, game_master_user, role: :game_master)
add_member(test_game, member_user_1, role: :member)
add_member(test_game, member_user_2, role: :member)
add_member(test_game, member_user_3, role: :member)
# non_member_user is NOT added
```

---

## Game-Level Permission Tests

Test file: `test/game_master_core_web/controllers/game_permissions_test.exs`

### 1. Manage Game Permission

**Endpoint**: `PUT /api/games/{game_id}`, `DELETE /api/games/{game_id}`

| User Type    | Expected Result | Status Code |
|--------------|-----------------|-------------|
| Admin        | ✅ Success      | 200/204     |
| Game Master  | ❌ Forbidden    | 403         |
| Member       | ❌ Forbidden    | 403         |
| Non-member   | ❌ Not Found    | 404         |

**Tests Required:**
- `test "admin can update game settings"`
- `test "admin can delete game"`
- `test "game master cannot update game settings"`
- `test "game master cannot delete game"`
- `test "member cannot update game settings"`
- `test "member cannot delete game"`
- `test "non-member cannot access game"`

### 2. Manage Members Permission

**Endpoints**:
- `POST /api/games/{game_id}/members` (add member)
- `DELETE /api/games/{game_id}/members/{user_id}` (remove member)
- `PUT /api/games/{game_id}/members/{user_id}/role` (change role)

| User Type    | Expected Result | Status Code |
|--------------|-----------------|-------------|
| Admin        | ✅ Success      | 200/201/204 |
| Game Master  | ❌ Forbidden    | 403         |
| Member       | ❌ Forbidden    | 403         |
| Non-member   | ❌ Not Found    | 404         |

**Tests Required:**
- `test "admin can add member to game"`
- `test "admin can remove member from game"`
- `test "admin can change member role"`
- `test "admin cannot change own role if only admin"` (edge case)
- `test "game master cannot add member"`
- `test "game master cannot remove member"`
- `test "game master cannot change member role"`
- `test "member cannot add member"`
- `test "member cannot remove member"`
- `test "member cannot change member role"`

---

## Entity-Level Permission Tests

Test file: `test/game_master_core_web/controllers/{entity}_authorization_test.exs`

Create separate test files for each entity type:
- `character_authorization_test.exs`
- `faction_authorization_test.exs`
- `location_authorization_test.exs`
- `quest_authorization_test.exs`
- `note_authorization_test.exs`

### Test Matrix Template

For **each entity type**, test **each action** against **each user type** and **each visibility level**.

#### Actions to Test

1. **View** - `GET /api/games/{game_id}/{entities}/{id}`
2. **Create** - `POST /api/games/{game_id}/{entities}`
3. **Update** - `PUT /api/games/{game_id}/{entities}/{id}`
4. **Delete** - `DELETE /api/games/{game_id}/{entities}/{id}`

#### Visibility Levels

- `private` - Only creator + admins/GMs
- `viewable` - Anyone can view, only creator + admins/GMs can edit
- `editable` - Anyone can view and edit

### 1. Admin Role Tests

**Expected**: Admin has full access to ALL entities regardless of visibility or ownership.

```
describe "admin role permissions" do
  test "admin can view private entity they don't own"
  test "admin can update private entity they don't own"
  test "admin can delete private entity they don't own"
  test "admin can view viewable entity"
  test "admin can update viewable entity they don't own"
  test "admin can delete viewable entity they don't own"
  test "admin can view editable entity"
  test "admin can update editable entity they don't own"
  test "admin can delete editable entity they don't own"
end
```

**Total per entity**: 9 tests × 5 entities = **45 tests**

### 2. Game Master Role Tests

**Expected**: Game Master has full access to ALL entities regardless of visibility or ownership.

```
describe "game master role permissions" do
  test "game master can view private entity they don't own"
  test "game master can update private entity they don't own"
  test "game master can delete private entity they don't own"
  test "game master can view viewable entity"
  test "game master can update viewable entity they don't own"
  test "game master can delete viewable entity they don't own"
  test "game master can view editable entity"
  test "game master can update editable entity they don't own"
  test "game master can delete editable entity they don't own"
end
```

**Total per entity**: 9 tests × 5 entities = **45 tests**

### 3. Entity Owner (Creator) Tests

**Expected**: Creator can always access their own entities regardless of visibility.

```
describe "entity owner permissions" do
  test "owner can view own private entity"
  test "owner can update own private entity"
  test "owner can delete own private entity"
  test "owner can view own viewable entity"
  test "owner can update own viewable entity"
  test "owner can delete own viewable entity"
  test "owner can view own editable entity"
  test "owner can update own editable entity"
  test "owner can delete own editable entity"
end
```

**Total per entity**: 9 tests × 5 entities = **45 tests**

### 4. Member (Non-Owner) with Private Visibility

**Expected**: Members CANNOT access private entities they don't own (unless explicitly shared).

```
describe "member access to private entities" do
  setup do
    # member_user_1 creates entity with visibility: "private"
    # member_user_2 attempts access
  end

  test "member cannot view another member's private entity" do
    # GET request -> 404 Not Found (entity filtered from query results)
  end

  test "member cannot update another member's private entity" do
    # PUT request -> 404 Not Found
  end

  test "member cannot delete another member's private entity" do
    # DELETE request -> 404 Not Found
  end
end
```

**Total per entity**: 3 tests × 5 entities = **15 tests**

### 5. Member (Non-Owner) with Viewable Visibility

**Expected**: Members CAN view but CANNOT edit/delete viewable entities.

```
describe "member access to viewable entities" do
  setup do
    # member_user_1 creates entity with visibility: "viewable"
    # member_user_2 attempts access
  end

  test "member can view another member's viewable entity" do
    # GET request -> 200 Success
    # Verify entity data returned
  end

  test "member cannot update another member's viewable entity" do
    # PUT request -> 403 Forbidden
  end

  test "member cannot delete another member's viewable entity" do
    # DELETE request -> 403 Forbidden
  end
end
```

**Total per entity**: 3 tests × 5 entities = **15 tests**

### 6. Member (Non-Owner) with Editable Visibility

**Expected**: Members CAN view, edit, and delete editable entities.

```
describe "member access to editable entities" do
  setup do
    # member_user_1 creates entity with visibility: "editable"
    # member_user_2 attempts access
  end

  test "member can view another member's editable entity" do
    # GET request -> 200 Success
  end

  test "member can update another member's editable entity" do
    # PUT request -> 200 Success
    # Verify changes persisted
  end

  test "member can delete another member's editable entity" do
    # DELETE request -> 204 No Content
    # Verify entity deleted
  end
end
```

**Total per entity**: 3 tests × 5 entities = **15 tests**

### 7. Non-Member Access Tests

**Expected**: Non-members CANNOT access ANY game entities.

```
describe "non-member access" do
  setup do
    # member_user_1 creates entities with all visibility levels
    # non_member_user (not in game) attempts access
  end

  test "non-member cannot view private entity" do
    # GET request -> 404 Not Found
  end

  test "non-member cannot view viewable entity" do
    # GET request -> 404 Not Found
  end

  test "non-member cannot view editable entity" do
    # GET request -> 404 Not Found
  end

  test "non-member cannot update any entity" do
    # PUT request -> 404 Not Found
  end

  test "non-member cannot delete any entity" do
    # DELETE request -> 404 Not Found
  end

  test "non-member cannot list game entities" do
    # GET /api/games/{game_id}/characters -> 404 Not Found
  end
end
```

**Total per entity**: 6 tests × 5 entities = **30 tests**

### 8. List Endpoint Filtering Tests

**Expected**: List endpoints return only accessible entities per user.

```
describe "list endpoint filtering" do
  setup do
    # Create mix of entities:
    # - 2 private entities (member_user_1)
    # - 2 viewable entities (member_user_1)
    # - 2 editable entities (member_user_1)
    # - 2 private entities (member_user_2)
  end

  test "admin sees all entities in game" do
    # GET /api/games/{game_id}/characters
    # Expect: all 8 entities
  end

  test "game master sees all entities in game" do
    # GET /api/games/{game_id}/characters
    # Expect: all 8 entities
  end

  test "member sees only their own and accessible entities" do
    # member_user_1 GET /api/games/{game_id}/characters
    # Expect: their 6 entities + member_user_2's 0 private = 6 total

    # member_user_2 GET /api/games/{game_id}/characters
    # Expect: their 2 entities + member_user_1's 4 viewable/editable = 6 total
  end

  test "non-member sees empty list" do
    # non_member_user GET /api/games/{game_id}/characters
    # Expect: 404 Not Found (no access to game)
  end
end
```

**Total per entity**: 4 tests × 5 entities = **20 tests**

---

## Entity Sharing Tests

Test file: `test/game_master_core_web/controllers/{entity}_sharing_test.exs`

Create separate sharing test files for each entity type.

### Sharing Endpoints

1. `POST /api/games/{game_id}/{entities}/{id}/share` - Share entity
2. `DELETE /api/games/{game_id}/{entities}/{id}/share` - Unshare entity
3. `GET /api/games/{game_id}/{entities}/{id}/shares` - List shares
4. `PUT /api/games/{game_id}/{entities}/{id}/visibility` - Update visibility

### 1. Share Entity Tests

#### Who Can Share

**Expected**: Only creator, admin, or game master can share.

```
describe "POST /share authorization" do
  setup do
    # member_user_1 creates a private entity
  end

  test "creator can share their entity with another user" do
    # member_user_1 shares with member_user_3, permission: "editor"
    # Expect: 200 Success
  end

  test "admin can share any entity" do
    # admin_user shares member_user_1's entity with member_user_3
    # Expect: 200 Success
  end

  test "game master can share any entity" do
    # game_master_user shares member_user_1's entity with member_user_3
    # Expect: 200 Success
  end

  test "non-owner member cannot share entity" do
    # member_user_2 tries to share member_user_1's entity
    # Expect: 403 Forbidden
  end

  test "non-member cannot share entity" do
    # non_member_user tries to share
    # Expect: 404 Not Found
  end
end
```

**Total per entity**: 5 tests × 5 entities = **25 tests**

#### Share Permission Levels

**Expected**: All three permission types work correctly.

```
describe "share permission types" do
  setup do
    # member_user_1 creates a private entity
  end

  test "sharing with 'editor' permission grants full access" do
    # Share with member_user_2, permission: "editor"
    # member_user_2 can view, update, delete
    # Verify all three operations succeed
  end

  test "sharing with 'viewer' permission grants view-only access" do
    # Share with member_user_2, permission: "viewer"
    # member_user_2 can view but not update/delete
    # Verify: GET 200, PUT 403, DELETE 403
  end

  test "sharing with 'blocked' permission denies all access" do
    # Share with member_user_2, permission: "blocked"
    # member_user_2 cannot view, update, or delete
    # Verify: GET 404, PUT 404, DELETE 404
  end

  test "blocked permission overrides viewable visibility" do
    # Create viewable entity
    # Share with member_user_2, permission: "blocked"
    # member_user_2 cannot access despite viewable visibility
    # Verify: GET 404
  end

  test "blocked permission overrides editable visibility" do
    # Create editable entity
    # Share with member_user_2, permission: "blocked"
    # member_user_2 cannot access despite editable visibility
    # Verify: GET 404
  end
end
```

**Total per entity**: 5 tests × 5 entities = **25 tests**

#### Share Updates (Upsert Behavior)

**Expected**: Sharing again updates existing share.

```
describe "share updates" do
  test "re-sharing with different permission updates existing share" do
    # Share with member_user_2, permission: "viewer"
    # Verify: can view, cannot edit

    # Re-share with permission: "editor"
    # Verify: can now edit
  end

  test "changing from editor to viewer removes edit access" do
    # Share with member_user_2, permission: "editor"
    # Verify: can edit

    # Re-share with permission: "viewer"
    # Verify: can view but cannot edit
  end

  test "changing from viewer to blocked removes all access" do
    # Share with member_user_2, permission: "viewer"
    # Verify: can view

    # Re-share with permission: "blocked"
    # Verify: cannot access
  end
end
```

**Total per entity**: 3 tests × 5 entities = **15 tests**

### 2. Unshare Entity Tests

```
describe "DELETE /share authorization" do
  setup do
    # member_user_1 creates entity and shares with member_user_2
  end

  test "creator can unshare their entity" do
    # member_user_1 unshares from member_user_2
    # Expect: 200 Success
    # Verify: member_user_2 loses access
  end

  test "admin can unshare any entity" do
    # admin_user unshares member_user_1's entity
    # Expect: 200 Success
  end

  test "game master can unshare any entity" do
    # game_master_user unshares member_user_1's entity
    # Expect: 200 Success
  end

  test "non-owner member cannot unshare entity" do
    # member_user_3 tries to unshare member_user_1's entity
    # Expect: 403 Forbidden
  end

  test "unsharing non-existent share returns not found" do
    # member_user_1 tries to unshare from user who doesn't have share
    # Expect: 404 Not Found
  end

  test "after unshare, user reverts to visibility-based access" do
    # Create viewable entity
    # Share with member_user_2, permission: "editor"
    # Verify: can edit

    # Unshare
    # Verify: can view but not edit (reverts to viewable behavior)
  end
end
```

**Total per entity**: 6 tests × 5 entities = **30 tests**

### 3. List Shares Tests

```
describe "GET /shares authorization" do
  setup do
    # member_user_1 creates entity
    # Share with member_user_2 (editor)
    # Share with member_user_3 (viewer)
  end

  test "creator can list shares on their entity" do
    # member_user_1 lists shares
    # Expect: 200 Success with 2 shares
  end

  test "admin can list shares on any entity" do
    # admin_user lists shares on member_user_1's entity
    # Expect: 200 Success with 2 shares
  end

  test "game master can list shares on any entity" do
    # game_master_user lists shares
    # Expect: 200 Success with 2 shares
  end

  test "member with editor share can list shares" do
    # member_user_2 (has editor share) lists shares
    # Expect: 200 Success with 2 shares
  end

  test "member with viewer share can list shares" do
    # member_user_3 (has viewer share) lists shares
    # Expect: 200 Success with 2 shares
  end

  test "member without access cannot list shares" do
    # Create private entity, no share for member_user_2
    # member_user_2 tries to list shares
    # Expect: 403 Forbidden
  end

  test "listed shares include user details and permission type" do
    # member_user_1 lists shares
    # Verify response includes:
    # - user.id, user.username, user.email
    # - permission ("editor"/"viewer")
    # - shared_at timestamp
  end
end
```

**Total per entity**: 7 tests × 5 entities = **35 tests**

### 4. Update Visibility Tests

```
describe "PUT /visibility authorization" do
  setup do
    # member_user_1 creates a private entity
  end

  test "creator can update visibility of their entity" do
    # member_user_1 updates to "viewable"
    # Expect: 200 Success
    # Verify: visibility changed
  end

  test "admin can update visibility of any entity" do
    # admin_user updates member_user_1's entity to "editable"
    # Expect: 200 Success
  end

  test "game master can update visibility of any entity" do
    # game_master_user updates visibility
    # Expect: 200 Success
  end

  test "non-owner member cannot update visibility" do
    # member_user_2 tries to update member_user_1's entity
    # Expect: 403 Forbidden
  end

  test "invalid visibility value returns bad request" do
    # member_user_1 tries to set visibility: "invalid"
    # Expect: 400 Bad Request
  end

  test "changing from private to viewable grants view access" do
    # Create private entity (member_user_2 has no access)
    # Verify: member_user_2 cannot view

    # Change to viewable
    # Verify: member_user_2 can now view
  end

  test "changing from editable to private removes access" do
    # Create editable entity (member_user_2 can edit)
    # Verify: member_user_2 can edit

    # Change to private
    # Verify: member_user_2 cannot access
  end

  test "visibility change does not affect explicit shares" do
    # Create private entity
    # Share with member_user_2, permission: "editor"
    # Verify: member_user_2 can edit

    # Change visibility to viewable
    # Verify: member_user_2 still has editor access (share takes precedence)
  end
end
```

**Total per entity**: 8 tests × 5 entities = **40 tests**

---

## Permission Metadata Tests

Test file: `test/game_master_core_web/controllers/permission_metadata_test.exs`

**Purpose**: Verify that API responses include correct permission metadata.

### Expected Response Structure

All entity responses should include:

```json
{
  "data": {
    "id": "...",
    "name": "...",
    // ... entity fields ...
    "can_edit": true,
    "can_delete": true,
    "can_share": false
  }
}
```

### 1. Single Entity Response Tests

```
describe "permission metadata in show responses" do
  test "admin gets all permissions true" do
    # member_user_1 creates private entity
    # admin_user GET /entities/{id}
    # Verify: can_edit: true, can_delete: true, can_share: true
  end

  test "game master gets all permissions true" do
    # game_master_user GET /entities/{id}
    # Verify: can_edit: true, can_delete: true, can_share: true
  end

  test "entity owner gets all permissions true" do
    # member_user_1 GET their own entity
    # Verify: can_edit: true, can_delete: true, can_share: true
  end

  test "member with editor share gets edit and delete true" do
    # Share with member_user_2, permission: "editor"
    # member_user_2 GET /entities/{id}
    # Verify: can_edit: true, can_delete: true, can_share: false
  end

  test "member with viewer share gets only can_edit false" do
    # Share with member_user_2, permission: "viewer"
    # member_user_2 GET /entities/{id}
    # Verify: can_edit: false, can_delete: false, can_share: false
  end

  test "member viewing viewable entity gets edit false" do
    # Create viewable entity
    # member_user_2 GET /entities/{id}
    # Verify: can_edit: false, can_delete: false, can_share: false
  end

  test "member viewing editable entity gets all true except share" do
    # Create editable entity
    # member_user_2 GET /entities/{id}
    # Verify: can_edit: true, can_delete: true, can_share: false
  end
end
```

**Total**: 7 tests × 5 entities = **35 tests**

### 2. List Response Tests

```
describe "permission metadata in index responses" do
  setup do
    # Create entities with different ownership and visibility
  end

  test "permissions calculated correctly for each entity in list" do
    # Create:
    # - entity_1 owned by member_user_1 (private)
    # - entity_2 owned by member_user_2 (viewable)
    # - entity_3 owned by member_user_1 (editable)

    # member_user_1 GET /entities
    # Verify entity_1: all true
    # Verify entity_2: can_edit false
    # Verify entity_3: all true (owner)
  end

  test "list only includes accessible entities" do
    # Create 5 private entities by different members
    # member_user_1 GET /entities
    # Verify: only returns their own entities
    # Verify: each has correct permissions
  end
end
```

**Total**: 2 tests × 5 entities = **10 tests**

---

## Edge Cases and Security Tests

Test file: `test/game_master_core_web/controllers/authorization_edge_cases_test.exs`

### 1. Cross-Game Access Tests

**Expected**: Users cannot access entities from games they don't belong to.

```
describe "cross-game access prevention" do
  setup do
    # Create game_1 with member_user_1
    # Create game_2 with member_user_2
    # member_user_1 creates entity in game_1
  end

  test "member from different game cannot access entity" do
    # member_user_2 tries to GET game_1's entity
    # Expect: 404 Not Found
  end

  test "admin from different game cannot access entity" do
    # Create admin_user_2 as admin of game_2
    # admin_user_2 tries to access game_1's entity
    # Expect: 404 Not Found
  end

  test "using wrong game_id in path returns not found" do
    # member_user_1 tries GET /api/games/{game_2_id}/entities/{game_1_entity_id}
    # Expect: 404 Not Found
  end
end
```

**Total**: 3 tests × 5 entities = **15 tests**

### 2. Share Self Tests

```
describe "sharing with self" do
  test "creator cannot share entity with themselves" do
    # member_user_1 tries to share their entity with themselves
    # Should either: succeed gracefully or return validation error
    # Document expected behavior
  end
end
```

**Total**: 1 test × 5 entities = **5 tests**

### 3. Share Non-Existent User Tests

```
describe "sharing with invalid user" do
  test "sharing with non-existent user returns error" do
    # member_user_1 tries to share with fake UUID
    # Expect: 404 Not Found or 422 Unprocessable Entity
  end

  test "sharing with user not in game returns error" do
    # member_user_1 tries to share with non_member_user
    # Expected behavior: should this work or fail?
    # Document and implement expected behavior
  end
end
```

**Total**: 2 tests × 5 entities = **10 tests**

### 4. Deleted Entity Tests

```
describe "accessing deleted entities" do
  setup do
    # Create entity, share with member_user_2, then delete
  end

  test "cannot access deleted entity even with share" do
    # member_user_2 tries to access deleted entity
    # Expect: 404 Not Found
  end

  test "cannot list shares for deleted entity" do
    # member_user_1 tries to list shares for deleted entity
    # Expect: 404 Not Found
  end
end
```

**Total**: 2 tests × 5 entities = **10 tests**

### 5. Concurrent Modification Tests

```
describe "concurrent permission changes" do
  test "removing share while user is accessing entity" do
    # Set up: member_user_2 has editor share
    # Simulate: unshare happens between list and update operations
    # Verify: update operation correctly fails with 403
  end

  test "changing visibility while user is accessing entity" do
    # Set up: member_user_2 accessing viewable entity
    # Change visibility to private
    # Verify: subsequent operations correctly denied
  end
end
```

**Total**: 2 tests × 5 entities = **10 tests**

### 6. Invalid Permission Values

```
describe "invalid permission values" do
  test "sharing with invalid permission type returns error" do
    # Try to share with permission: "invalid"
    # Expect: 400 Bad Request or 422 Unprocessable Entity
  end

  test "case sensitivity of permission values" do
    # Try permission: "EDITOR" (uppercase)
    # Document: should this work or fail?
  end
end
```

**Total**: 2 tests × 5 entities = **10 tests**

### 7. Malformed Request Tests

```
describe "malformed requests" do
  test "share without permission field returns error" do
    # POST /share with {user_id: "..."} but no permission
    # Expect: 400 Bad Request
  end

  test "share without user_id returns error" do
    # POST /share with {permission: "editor"} but no user_id
    # Expect: 400 Bad Request
  end

  test "invalid UUID format returns error" do
    # Try to access entity with id: "not-a-uuid"
    # Expect: 400 Bad Request or 404 Not Found
  end
end
```

**Total**: 3 tests × 5 entities = **15 tests**

---

## Test Organization

### Directory Structure

```
test/game_master_core_web/controllers/
├── game_permissions_test.exs           # Game-level permissions
│
├── character_authorization_test.exs    # Character CRUD permissions
├── character_sharing_test.exs          # Character sharing endpoints
│
├── faction_authorization_test.exs      # Faction CRUD permissions
├── faction_sharing_test.exs            # Faction sharing endpoints
│
├── location_authorization_test.exs     # Location CRUD permissions
├── location_sharing_test.exs           # Location sharing endpoints
│
├── quest_authorization_test.exs        # Quest CRUD permissions
├── quest_sharing_test.exs              # Quest sharing endpoints
│
├── note_authorization_test.exs         # Note CRUD permissions
├── note_sharing_test.exs               # Note sharing endpoints
│
├── permission_metadata_test.exs        # Response metadata tests
└── authorization_edge_cases_test.exs   # Edge cases and security tests
```

### Test Helpers

Create shared test helpers in `test/support/authorization_test_helpers.ex`:

```elixir
defmodule GameMasterCoreWeb.AuthorizationTestHelpers do
  @moduledoc """
  Shared helpers for authorization testing.
  """

  def setup_test_game_and_users(_context) do
    # Create test game with all required users
    # Return map with all users and game
  end

  def create_entity_for_user(entity_type, user, game, attrs \\ %{}) do
    # Helper to create entities with specific visibility/owner
  end

  def share_entity_with_user(entity_type, entity, from_user, to_user, permission) do
    # Helper to create shares
  end

  def assert_success_response(conn, expected_status \\ 200) do
    # Assert successful response with status code
  end

  def assert_unauthorized_response(conn, expected_status \\ 403) do
    # Assert unauthorized response
  end

  def assert_not_found_response(conn) do
    # Assert 404 response
  end

  def assert_has_permissions(entity_data, can_edit, can_delete, can_share) do
    # Assert permission metadata
  end
end
```

### Shared Setup

Create a common setup module:

```elixir
defmodule GameMasterCoreWeb.AuthorizationTestSetup do
  @moduledoc """
  Common setup for authorization tests.
  """

  def setup_test_users do
    admin = create_user("admin@example.com")
    game_master = create_user("gm@example.com")
    member_1 = create_user("member1@example.com")
    member_2 = create_user("member2@example.com")
    member_3 = create_user("member3@example.com")
    non_member = create_user("nonmember@example.com")

    %{
      admin: admin,
      game_master: game_master,
      member_1: member_1,
      member_2: member_2,
      member_3: member_3,
      non_member: non_member
    }
  end

  def setup_test_game(users) do
    game = create_game(users.admin)
    add_member(game, users.game_master, :game_master)
    add_member(game, users.member_1, :member)
    add_member(game, users.member_2, :member)
    add_member(game, users.member_3, :member)

    %{game: game, users: users}
  end
end
```

---

## Test Count Summary

### By Category

| Category                          | Tests per Entity | Entities | Total Tests |
|-----------------------------------|------------------|----------|-------------|
| **Game-Level Permissions**        | N/A              | N/A      | 16          |
| **Admin Role Tests**              | 9                | 5        | 45          |
| **Game Master Role Tests**        | 9                | 5        | 45          |
| **Entity Owner Tests**            | 9                | 5        | 45          |
| **Member Private Access**         | 3                | 5        | 15          |
| **Member Viewable Access**        | 3                | 5        | 15          |
| **Member Editable Access**        | 3                | 5        | 15          |
| **Non-Member Access**             | 6                | 5        | 30          |
| **List Filtering**                | 4                | 5        | 20          |
| **Share Authorization**           | 5                | 5        | 25          |
| **Share Permission Types**        | 5                | 5        | 25          |
| **Share Updates**                 | 3                | 5        | 15          |
| **Unshare Tests**                 | 6                | 5        | 30          |
| **List Shares Tests**             | 7                | 5        | 35          |
| **Update Visibility Tests**       | 8                | 5        | 40          |
| **Permission Metadata Show**      | 7                | 5        | 35          |
| **Permission Metadata List**      | 2                | 5        | 10          |
| **Cross-Game Access**             | 3                | 5        | 15          |
| **Share Self**                    | 1                | 5        | 5           |
| **Share Invalid User**            | 2                | 5        | 10          |
| **Deleted Entity**                | 2                | 5        | 10          |
| **Concurrent Modification**       | 2                | 5        | 10          |
| **Invalid Permission Values**     | 2                | 5        | 10          |
| **Malformed Requests**            | 3                | 5        | 15          |

### **TOTAL ESTIMATED TESTS: ~525 tests**

---

## Implementation Guidelines

### 1. Test Data Consistency

- Use factories or fixtures for consistent test data creation
- Always clean up test data between tests
- Use unique identifiers to avoid conflicts

### 2. HTTP Status Code Expectations

| Scenario                          | Expected Status |
|-----------------------------------|-----------------|
| Successful read                   | 200 OK          |
| Successful create                 | 201 Created     |
| Successful delete                 | 204 No Content  |
| Validation error                  | 400 Bad Request |
| Forbidden (has access to game)    | 403 Forbidden   |
| Not found (no game access)        | 404 Not Found   |
| Not found (entity doesn't exist)  | 404 Not Found   |
| Validation error (business logic) | 422 Unprocessable |

### 3. Authentication

All tests must include valid authentication tokens:

```elixir
conn =
  build_conn()
  |> put_req_header("authorization", "Bearer #{token}")
  |> get(path)
```

### 4. Assertions

Every test should verify:
1. **Status code** - Correct HTTP status
2. **Response body** - Contains expected data (for success cases)
3. **Database state** - Changes persisted correctly (for mutations)
4. **Error messages** - Clear, helpful error messages (for failures)

### 5. Test Independence

- Each test should be fully independent
- Don't rely on test execution order
- Clean up all created resources

### 6. Performance Considerations

- Use database transactions for test isolation
- Avoid unnecessary database queries in setup
- Consider using ExMachina or similar for fixtures

---

## Acceptance Criteria

All tests must pass before Phase 4 is considered complete:

✅ **All 525+ tests passing**
✅ **100% test coverage** on authorization code paths
✅ **No flaky tests** - all tests deterministic
✅ **Clear error messages** for all failure scenarios
✅ **Documentation updated** with test results

---

## Notes for Implementation

### Priority Order

Implement tests in this order:

1. **Game-level permissions** (foundation)
2. **Admin/Game Master role tests** (should always pass)
3. **Entity owner tests** (straightforward)
4. **Visibility-based access tests** (core functionality)
5. **Sharing tests** (most complex)
6. **Permission metadata tests** (verify responses)
7. **Edge cases** (catch bugs)

### Common Pitfalls to Avoid

1. **Not testing all entity types** - Easy to test only Character and forget others
2. **Hardcoded user IDs** - Use dynamic test data
3. **Missing negative tests** - Always test failure cases
4. **Ignoring response format** - Verify JSON structure
5. **Not testing permissions in list responses** - Each item should have metadata
6. **Forgetting non-member tests** - Critical security boundary

### Questions to Resolve

Document answers to these questions during implementation:

1. Should sharing with non-game-members be allowed?
2. Should users be able to share entities with themselves?
3. How should blocked shares interact with admin/GM access?
4. Should visibility changes trigger notifications?
5. What happens to shares when entity is deleted?

---

## Maintenance

This document should be updated when:

- New entity types are added
- Authorization rules change
- New endpoints are added
- Security vulnerabilities are discovered

**Document Owner**: Development Team
**Last Updated**: 2025-11-01
**Version**: 1.0
