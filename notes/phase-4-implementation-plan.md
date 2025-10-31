# Phase 4 Implementation Plan: API & Responses

**Date:** 2025-10-31
**Status:** In Progress
**Related:** authorization-and-permissions-proposal.md

---

## Work Completed to Date

### Phase 1: Schema & Migrations ✅ COMPLETE
- ✅ Updated `game_members` table to support new roles (`admin`, `game_master`, `member`)
- ✅ Added `visibility` field to all entity tables (characters, factions, locations, quests, notes)
- ✅ Created `entity_shares` table for ACL permissions
- ✅ Created EntityShare schema with proper validations

### Phase 2: Core Authorization ✅ COMPLETE
- ✅ Built `Authorization` module with:
  - Game-level RBAC permission checks (`authorized?/2`)
  - Entity-level ACL permission checks (`can_access_entity?/3`)
  - Entity sharing functions (`share_entity/4`, `unshare_entity/3`, `list_entity_shares/2`)
  - Optimized database queries for entity filtering (`scope_entity_query/3`)
- ✅ Updated `Scope` module to automatically load user role in game context
- ✅ Proper cascade deletes for entity_shares via database constraints

### Phase 3: Context Integration ✅ COMPLETE
- ✅ Integrated authorization checks into all context modules:
  - Characters, Factions, Locations, Quests, Notes
- ✅ Updated all CRUD operations to enforce permissions
- ✅ Applied entity visibility filtering to list operations
- ✅ Added authorization error handling (`:unauthorized` returns)

### Phase 4: API & Responses 🚧 IN PROGRESS
**Current Status:** Ready to begin

---

## Phase 4 Goals

1. **Expose sharing functionality** via REST API endpoints
2. **Add role management** endpoints for game admins
3. **Update JSON responses** to include permission metadata
4. **Add E2E tests** for all new endpoints
5. **Update API documentation** (Swagger/OpenAPI)

---

## Task Breakdown

### Task 1: Add Entity Sharing Endpoints

For **each entity type** (Character, Faction, Location, Quest, Note), add the following endpoints to their respective controllers:

#### 1.1 Share Entity (Create Share)
```
POST /api/games/:game_id/:entity_type/:entity_id/share
```

**Request Body:**
```json
{
  "user_id": "uuid",
  "permission": "editor" | "viewer" | "blocked"
}
```

**Response:** `200 OK` or `403 Forbidden`

**Implementation:**
- Calls `Authorization.share_entity/4`
- Only creator (or admin/GM) can share
- Validates user is a member of the game

#### 1.2 Remove Share (Delete Share)
```
DELETE /api/games/:game_id/:entity_type/:entity_id/share/:user_id
```

**Response:** `200 OK` or `403 Forbidden`

**Implementation:**
- Calls `Authorization.unshare_entity/3`
- Only creator (or admin/GM) can unshare

#### 1.3 List Shares
```
GET /api/games/:game_id/:entity_type/:entity_id/shares
```

**Response:**
```json
{
  "data": [
    {
      "user_id": "uuid",
      "user": { "id": "uuid", "username": "..." },
      "permission": "editor",
      "shared_at": "timestamp"
    }
  ]
}
```

**Implementation:**
- Calls `Authorization.list_entity_shares/2`
- Only creator (or admin/GM) can view shares

#### 1.4 Update Visibility
```
PATCH /api/games/:game_id/:entity_type/:entity_id/visibility
```

**Request Body:**
```json
{
  "visibility": "private" | "viewable" | "editable"
}
```

**Response:**
```json
{
  "data": {
    "id": "uuid",
    "visibility": "private"
  }
}
```

**Implementation:**
- Uses existing `update_*` context function
- Only creator (or admin/GM) can change visibility

---

### Task 2: Add Game Role Management Endpoints

Add to `GameController`:

#### 2.1 Update Member Role
```
PATCH /api/games/:game_id/members/:user_id/role
```

**Request Body:**
```json
{
  "role": "admin" | "game_master" | "member"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "game_id": "uuid",
    "role": "admin"
  }
}
```

**Implementation:**
- Create new `Games.change_member_role/4` function
- Only admins can change roles
- Cannot demote the game owner (optional business rule)

#### 2.2 List Game Members with Roles
```
GET /api/games/:game_id/members
```

**Response:**
```json
{
  "data": [
    {
      "user_id": "uuid",
      "user": { "id": "uuid", "username": "...", "email": "..." },
      "role": "admin",
      "joined_at": "timestamp"
    }
  ]
}
```

**Implementation:**
- Create `Games.list_members_with_roles/2`
- Preload user data
- Available to all game members

---

### Task 3: Update JSON Views

#### 3.1 Game JSON View
Update `game_json.ex` to include user's role:

```elixir
def show(%{game: game, scope: scope}) do
  %{
    data: %{
      id: game.id,
      name: game.name,
      content: game.content,
      setting: game.setting,
      owner_id: game.owner_id,
      your_role: scope.role,  # NEW
      inserted_at: game.inserted_at,
      updated_at: game.updated_at
    }
  }
end
```

#### 3.2 Entity JSON Views (All Entities)
Update all entity JSON views to include:

```elixir
def show(%{character: character, scope: scope}) do
  %{
    data: %{
      id: character.id,
      name: character.name,
      content: character.content,
      visibility: character.visibility,  # NEW
      can_edit: Authorization.can_access_entity?(scope, character, :edit),  # NEW
      can_delete: Authorization.can_access_entity?(scope, character, :delete),  # NEW
      can_share: character.user_id == scope.user.id or scope.role in [:admin, :game_master],  # NEW
      # ... other fields
      user_id: character.user_id,
      game_id: character.game_id,
      inserted_at: character.inserted_at,
      updated_at: character.updated_at
    }
  }
end
```

**Affected files:**
- `character_json.ex`
- `faction_json.ex`
- `location_json.ex`
- `quest_json.ex`
- `note_json.ex`

---

### Task 4: Add Context Functions

#### 4.1 Games Context
Add to `lib/game_master_core/games.ex`:

```elixir
@doc """
Change a member's role in the game.
Only admins can change roles.
"""
def change_member_role(%Scope{} = scope, game_id, user_id, new_role)
  when new_role in ["admin", "game_master", "member"] do
  if Authorization.authorized?(scope, :manage_members) do
    # Update the GameMembership record
    # Return {:ok, membership} or {:error, changeset}
  else
    {:error, :unauthorized}
  end
end

@doc """
List all members of a game with their roles and user data.
"""
def list_members_with_roles(%Scope{} = scope, game_id) do
  # Query game_members
  # Preload user data
  # Return list of memberships with user info
end
```

---

### Task 5: E2E API Tests

#### 5.1 Character Sharing Tests
Create `test/game_master_core_web/controllers/character_sharing_test.exs`:

```elixir
defmodule GameMasterCoreWeb.CharacterSharingTest do
  use GameMasterCoreWeb.ConnCase

  describe "POST /api/games/:game_id/characters/:id/share" do
    test "creator can share character with editor permission"
    test "creator can share character with viewer permission"
    test "creator can share character with blocked permission"
    test "non-creator cannot share others' characters"
    test "cannot share with user not in game"
    test "admin can share any character"
    test "game master can share any character"
  end

  describe "DELETE /api/games/:game_id/characters/:id/share/:user_id" do
    test "creator can remove share"
    test "non-creator cannot remove share"
    test "admin can remove any share"
  end

  describe "GET /api/games/:game_id/characters/:id/shares" do
    test "creator can view shares"
    test "non-creator cannot view shares"
    test "admin can view any shares"
  end

  describe "PATCH /api/games/:game_id/characters/:id/visibility" do
    test "creator can change visibility to viewable"
    test "creator can change visibility to editable"
    test "creator can change visibility to private"
    test "non-creator cannot change visibility"
    test "admin can change any visibility"
  end

  describe "shared entity access" do
    test "user with editor permission can edit character"
    test "user with viewer permission can view but not edit"
    test "user with blocked permission cannot view"
  end
end
```

**Repeat similar tests for:**
- Factions
- Locations
- Quests
- Notes

#### 5.2 Role Management Tests
Create `test/game_master_core_web/controllers/game_role_test.exs`:

```elixir
defmodule GameMasterCoreWeb.GameRoleTest do
  use GameMasterCoreWeb.ConnCase

  describe "PATCH /api/games/:game_id/members/:user_id/role" do
    test "admin can promote member to game_master"
    test "admin can promote member to admin"
    test "admin can demote game_master to member"
    test "game_master cannot change roles"
    test "member cannot change roles"
    test "cannot change role of user not in game"
  end

  describe "GET /api/games/:game_id/members" do
    test "returns all members with roles"
    test "includes user data"
    test "any game member can view"
  end
end
```

#### 5.3 JSON Response Tests
Create `test/game_master_core_web/controllers/permission_metadata_test.exs`:

```elixir
defmodule GameMasterCoreWeb.PermissionMetadataTest do
  use GameMasterCoreWeb.ConnCase

  describe "game JSON includes role" do
    test "admin sees their admin role"
    test "game_master sees their game_master role"
    test "member sees their member role"
  end

  describe "entity JSON includes permission flags" do
    test "creator sees can_edit: true, can_delete: true, can_share: true"
    test "member with viewer share sees can_edit: false"
    test "member with editor share sees can_edit: true"
    test "admin sees can_edit: true for all entities"
  end

  describe "entity JSON includes visibility" do
    test "private entity shows visibility: private"
    test "viewable entity shows visibility: viewable"
    test "editable entity shows visibility: editable"
  end
end
```

---

### Task 6: Update Router

Update `lib/game_master_core_web/router.ex`:

```elixir
scope "/api/games/:game_id", GameMasterCoreWeb do
  pipe_through [:api, :require_authenticated_user, :fetch_game]

  # Existing routes...
  
  # Character sharing routes
  post "/characters/:id/share", CharacterController, :share
  delete "/characters/:id/share/:user_id", CharacterController, :unshare
  get "/characters/:id/shares", CharacterController, :list_shares
  patch "/characters/:id/visibility", CharacterController, :update_visibility
  
  # Faction sharing routes
  post "/factions/:id/share", FactionController, :share
  delete "/factions/:id/share/:user_id", FactionController, :unshare
  get "/factions/:id/shares", FactionController, :list_shares
  patch "/factions/:id/visibility", FactionController, :update_visibility
  
  # Location sharing routes
  post "/locations/:id/share", LocationController, :share
  delete "/locations/:id/share/:user_id", LocationController, :unshare
  get "/locations/:id/shares", LocationController, :list_shares
  patch "/locations/:id/visibility", LocationController, :update_visibility
  
  # Quest sharing routes
  post "/quests/:id/share", QuestController, :share
  delete "/quests/:id/share/:user_id", QuestController, :unshare
  get "/quests/:id/shares", QuestController, :list_shares
  patch "/quests/:id/visibility", QuestController, :update_visibility
  
  # Note sharing routes
  post "/notes/:id/share", NoteController, :share
  delete "/notes/:id/share/:user_id", NoteController, :unshare
  get "/notes/:id/shares", NoteController, :list_shares
  patch "/notes/:id/visibility", NoteController, :update_visibility
  
  # Game role management
  patch "/members/:user_id/role", GameController, :update_member_role
  get "/members", GameController, :list_members
end
```

---

### Task 7: Update Swagger Documentation

For each new endpoint, add Swagger annotations:

#### Example for Character Controller:

```elixir
swagger_path :share do
  post "/api/games/{game_id}/characters/{id}/share"
  summary "Share a character with another user"
  description "Grant explicit access permissions to another user"
  produces "application/json"
  
  parameters do
    game_id :path, :string, "Game ID", required: true
    id :path, :string, "Character ID", required: true
    body :body, Schema.ref(:ShareRequest), "Share parameters", required: true
  end
  
  response 200, "Success"
  response 403, "Forbidden"
  response 404, "Not found"
end

def swagger_definitions do
  %{
    ShareRequest: swagger_schema do
      properties do
        user_id :string, "User ID to share with", required: true
        permission :string, "Permission level", enum: ["editor", "viewer", "blocked"], required: true
      end
    end,
    # ... other definitions
  }
end
```

---

## Implementation Checklist

### Controllers (20 endpoints total)

#### Character Controller
- [ ] Add `share/2` action
- [ ] Add `unshare/2` action
- [ ] Add `list_shares/2` action
- [ ] Add `update_visibility/2` action

#### Faction Controller
- [ ] Add `share/2` action
- [ ] Add `unshare/2` action
- [ ] Add `list_shares/2` action
- [ ] Add `update_visibility/2` action

#### Location Controller
- [ ] Add `share/2` action
- [ ] Add `unshare/2` action
- [ ] Add `list_shares/2` action
- [ ] Add `update_visibility/2` action

#### Quest Controller
- [ ] Add `share/2` action
- [ ] Add `unshare/2` action
- [ ] Add `list_shares/2` action
- [ ] Add `update_visibility/2` action

#### Note Controller
- [ ] Add `share/2` action
- [ ] Add `unshare/2` action
- [ ] Add `list_shares/2` action
- [ ] Add `update_visibility/2` action

#### Game Controller
- [ ] Add `update_member_role/2` action
- [ ] Add `list_members/2` action

### JSON Views (7 files)

- [ ] Update `game_json.ex` - add `your_role`
- [ ] Update `character_json.ex` - add visibility + permission flags
- [ ] Update `faction_json.ex` - add visibility + permission flags
- [ ] Update `location_json.ex` - add visibility + permission flags
- [ ] Update `quest_json.ex` - add visibility + permission flags
- [ ] Update `note_json.ex` - add visibility + permission flags
- [ ] Create `member_json.ex` - for member list responses

### Context Functions

- [ ] Add `Games.change_member_role/4`
- [ ] Add `Games.list_members_with_roles/2`

### Router

- [ ] Add 20 sharing routes (4 per entity type)
- [ ] Add 2 role management routes

### Tests (50+ tests estimated)

- [ ] Character sharing tests (10 tests)
- [ ] Faction sharing tests (10 tests)
- [ ] Location sharing tests (10 tests)
- [ ] Quest sharing tests (10 tests)
- [ ] Note sharing tests (10 tests)
- [ ] Role management tests (5 tests)
- [ ] JSON metadata tests (10 tests)

### Documentation

- [ ] Update Swagger for all new endpoints (22 endpoints)
- [ ] Add inline documentation to new controller actions
- [ ] Update README if needed

---

## Estimated Effort

- **Controllers & Routes:** 4-6 hours
- **JSON Views:** 2-3 hours
- **Context Functions:** 1-2 hours
- **Tests:** 8-12 hours
- **Swagger Documentation:** 3-4 hours
- **Testing & Debugging:** 4-6 hours

**Total:** 22-33 hours (3-4 days of focused work)

---

## Testing Strategy

### Manual Testing Workflow

1. **Setup:** Create test game with admin, game_master, and 2 members
2. **Test sharing flow:**
   - Member creates private character
   - Member shares with viewer permission
   - Verify viewer can GET but not PATCH
   - Member shares with editor permission
   - Verify editor can GET and PATCH
3. **Test role management:**
   - Admin promotes member to game_master
   - Verify game_master can edit all entities
   - Verify game_master cannot change roles
4. **Test JSON responses:**
   - Verify `your_role` in game response
   - Verify `can_edit`, `can_delete`, `can_share` flags
   - Verify `visibility` field

### Automated Testing

Run full test suite with:
```bash
mix test
```

Run specific test files:
```bash
mix test test/game_master_core_web/controllers/character_sharing_test.exs
```

---

## Success Criteria

Phase 4 is complete when:

- ✅ All 22 new endpoints are implemented
- ✅ All JSON views include permission metadata
- ✅ All E2E tests pass (50+ tests)
- ✅ Swagger documentation is updated
- ✅ Manual testing scenarios pass
- ✅ No regressions in existing functionality
- ✅ `mix precommit` passes

---

## Next Steps After Phase 4

Once Phase 4 is complete:

1. Review and merge into main branch
2. Begin Phase 5: Documentation & Monitoring
3. Consider performance testing with realistic data
4. Plan production deployment strategy
