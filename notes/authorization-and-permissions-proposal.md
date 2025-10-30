# Hybrid RBAC + ACL Authorization System Proposal

**Date:** 2025-10-30
**Status:** Proposal / Investigation
**Author:** Claude Code

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Requirements](#requirements)
3. [Proposed Solution Overview](#proposed-solution-overview)
4. [Role Definitions](#role-definitions)
5. [Entity-Level Permissions](#entity-level-permissions)
6. [Authorization Resolution Logic](#authorization-resolution-logic)
7. [Schema Changes](#schema-changes)
8. [Implementation Details](#implementation-details)
9. [API Endpoints](#api-endpoints)
10. [Permission Matrix](#permission-matrix)
11. [Migration & Rollout Strategy](#migration--rollout-strategy)
12. [Performance Considerations](#performance-considerations)
13. [Testing Strategy](#testing-strategy)
14. [Open Questions](#open-questions)

---

## Current State Analysis

### Existing Data Structures

**User** (`lib/game_master_core/accounts/user.ex:8-20`)
- Binary UUID primary key
- `many_to_many :games` through `game_members` join table
- Standard phx.gen.auth fields (email, password, confirmed_at)
- Additional fields: username, avatar_url

**Game** (`lib/game_master_core/games/game.ex:8-18`)
- Binary UUID primary key
- `many_to_many :members` through `game_members` join table
- `belongs_to :owner` (User) - single owner model
- Content fields: name, content, content_plain_text, setting

**GameMembership** (`lib/game_master_core/games/game_membership.ex:11-17`)
- Join table with explicit schema
- Fields: `user_id`, `game_id`, `role`
- Role validation: `["member", "owner"]`
- Unique constraint on `[user_id, game_id]`
- Has timestamps for audit trail

**Scope** (`lib/game_master_core/accounts/scope.ex:22`)
- Simple struct: `%{user: nil, game: nil}`
- Used consistently throughout contexts
- Documentation mentions it can carry authorization fields
- Extended in UserAuth for game context

### Current Authorization Patterns

**Game-level** (`lib/game_master_core/games.ex:270-281`)
```elixir
defp can_modify_game?(%Scope{} = scope, %Game{} = game) do
  game.owner_id == scope.user.id
end

defp can_access_game?(%Scope{} = scope, %Game{} = game) do
  user_id = scope.user.id

  game.owner_id == user_id ||
    Repo.exists?(
      from m in GameMembership, where: m.game_id == ^game.id and m.user_id == ^user_id
    )
end
```

- `can_modify_game?/2` - Only game owner
- `can_access_game?/2` - Owner OR any member
- `add_member/4`, `remove_member/3` - Owner only

**Entity-level** (Characters, Factions, Locations, Quests, Notes)
- All entities have `game_id` and `user_id` fields
- Access is currently **game-scoped only**
- No distinction between owner/member permissions
- Anyone with game access can create/modify/delete entities
- Example from `lib/game_master_core/characters.ex:44-76`:
  ```elixir
  def list_characters_for_game(%Scope{} = scope) do
    from(c in Character, where: c.game_id == ^scope.game.id)
    |> Repo.all()
  end
  ```

### Identified Gaps

1. **No fine-grained permissions** - Members have same entity access as owners
2. **No role-based actions** - Only binary owner/member distinction
3. **No permission scoping on entities** - Can't restrict who edits specific entities
4. **No audit trail** - Can't track who performed actions on entities
5. **No visibility controls** - Can't make entities private or selectively shared

---

## Requirements

Based on discussion, the system needs:

### Role-Based Permissions

- **Admin**: Can do everything (game management + all entities)
- **Game Master**: Can edit everything, but cannot change game data and memberships
- **Member**: Can edit their own stuff, subject to entity-level permissions

### Entity-Level Permissions

Users with correct permissions should be able to:
- Mark entities as **globally editable, viewable, or private**
- **Share** entities with other users of any role
- Grant shared users: **editor**, **viewer**, or **blocked** access

---

## Proposed Solution Overview

A **two-layer permission system** combining:

1. **Role-Based Access Control (RBAC)** - Game-level permissions via user roles
2. **Access Control Lists (ACL)** - Entity-level permissions for fine-grained sharing

### Key Design Principles

- **Simple & Progressive** - Start with basic roles, extend as needed
- **Backward Compatible** - Existing games continue working
- **Scope-centric** - Leverage existing Scope pattern
- **Entity-agnostic** - Permissions apply uniformly across entity types
- **Performance-conscious** - Optimize for common queries

---

## Role Definitions

### Admin

**Game Management**: ✅ Full control (settings, deletion)
**Member Management**: ✅ Full control (add/remove, change roles)
**Entity Access**: ✅ Can view/edit **all entities** (bypasses entity permissions)
**Assignment**: Typically the game owner (`game.owner_id`)

**Use Case**: The primary game creator who has full control over the entire game.

### Game Master

**Game Management**: ❌ Cannot modify game settings or delete game
**Member Management**: ❌ Cannot manage members
**Entity Access**: ✅ Can view/edit **all entities** (bypasses entity permissions)
**Assignment**: Trusted co-GMs who help manage content

**Use Case**: Co-GMs or assistant game masters who help create and manage game content but shouldn't be able to change fundamental game settings or membership.

### Member

**Game Management**: ❌ No access
**Member Management**: ❌ No access
**Entity Access**: ⚠️ Subject to entity-level permissions (see below)
**Assignment**: Default role for players

**Use Case**: Regular players in the game who manage their own characters and content.

---

## Entity-Level Permissions

### Global Visibility Settings

When a Member creates an entity, they set its **visibility**:

#### Private (default)
- Only the creator can view/edit
- Admins/Game Masters can still see/edit (role override)
- Must be explicitly shared to grant access to other Members
- **Use Case**: Personal character notes, secret plans

#### Viewable
- Anyone in the game can **view**
- Only creator (and Admins/GMs) can **edit**
- Other Members get read-only access
- **Use Case**: Published lore, shared backstories

#### Editable
- Anyone in the game can **view and edit**
- Useful for shared resources like world lore, maps, etc.
- **Use Case**: Collaborative world-building, shared party inventory

### Entity Sharing System

Members can **grant explicit permissions** to specific users:

#### Editor Permission
- User can view and edit this specific entity
- Overrides "private" and "viewable" restrictions
- Example: Share a character sheet with another player to co-develop

#### Viewer Permission
- User can view but not edit this entity
- Useful for "read-only" sharing
- Example: Share a secret note with one player

#### Blocked Permission
- User **cannot** view this entity
- Overrides "viewable" and "editable" settings
- Example: Hide a spoiler entity from a specific player
- Does **not** affect Admins/Game Masters (they always have access)

---

## Authorization Resolution Logic

When a user attempts to access an entity, check in this order:

```
1. Is user an Admin or Game Master?
   → YES: Allow all actions (bypass entity permissions)
   → NO: Continue to step 2

2. Is user a Member?
   a. Check explicit entity shares:
      - If "blocked": DENY (even if creator)
      - If "editor": Allow edit
      - If "viewer": Allow view only

   b. Is user the creator (entity.user_id == user.id)?
      → YES: Allow edit

   c. Check global visibility:
      - "editable": Allow edit
      - "viewable": Allow view only
      - "private": DENY

   d. Default: DENY

3. No valid role found: DENY
```

### Implementation Pseudocode

```elixir
def can_access_entity?(scope, entity, action) do
  role = get_user_role(scope.user.id, scope.game)

  # Layer 1: Role-based bypass
  if role in [:admin, :game_master] do
    true
  else
    # Layer 2: Entity-level ACL for Members
    check_member_entity_access(scope.user.id, entity, action)
  end
end

defp check_member_entity_access(user_id, entity, action) do
  # Step 1: Check explicit shares
  case get_entity_share(entity, user_id) do
    %{permission: "blocked"} -> false
    %{permission: "editor"} -> true
    %{permission: "viewer"} -> action == :view
    nil -> check_ownership_and_visibility(user_id, entity, action)
  end
end

defp check_ownership_and_visibility(user_id, entity, action) do
  # Step 2: Check ownership
  if entity.user_id == user_id do
    true
  else
    # Step 3: Check global visibility
    case entity.visibility do
      "editable" -> true
      "viewable" -> action == :view
      "private" -> false
    end
  end
end
```

---

## Schema Changes

### 1. Update GameMembership Roles

**Migration:**
```elixir
# priv/repo/migrations/XXXXXX_update_game_membership_roles.exs
defmodule GameMasterCore.Repo.Migrations.UpdateGameMembershipRoles do
  use Ecto.Migration

  def up do
    # Current roles: ["member", "owner"]
    # New roles: ["admin", "game_master", "member"]

    # Note: "owner" entries might not exist if ownership is tracked via game.owner_id
    # Keep backward compatibility by mapping "owner" -> "admin" if it exists
    execute "UPDATE game_members SET role = 'admin' WHERE role = 'owner'"
  end

  def down do
    execute "UPDATE game_members SET role = 'owner' WHERE role = 'admin'"
  end
end
```

**Schema Update:**
```elixir
# lib/game_master_core/games/game_membership.ex
def changeset(membership, attrs) do
  membership
  |> cast(attrs, [:user_id, :game_id, :role])
  |> validate_required([:user_id, :game_id, :role])
  |> validate_inclusion(:role, ["admin", "game_master", "member"])  # Updated
  |> foreign_key_constraint(:user_id)
  |> foreign_key_constraint(:game_id)
  |> unique_constraint([:user_id, :game_id])
end
```

### 2. Add Visibility Field to All Entity Tables

**Migrations (one per entity type):**

```elixir
# priv/repo/migrations/XXXXXX_add_visibility_to_characters.exs
defmodule GameMasterCore.Repo.Migrations.AddVisibilityToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :visibility, :string, default: "private", null: false
    end

    create index(:characters, [:visibility])
  end
end

# Repeat for: factions, locations, quests, notes
# - XXXXXX_add_visibility_to_factions.exs
# - XXXXXX_add_visibility_to_locations.exs
# - XXXXXX_add_visibility_to_quests.exs
# - XXXXXX_add_visibility_to_notes.exs
```

**Schema Updates:**

```elixir
# lib/game_master_core/characters/character.ex
schema "characters" do
  field :name, :string
  field :content, :string
  field :content_plain_text, :string
  field :visibility, :string, default: "private"  # NEW
  field :class, :string
  field :level, :integer
  field :tags, {:array, :string}, default: []
  field :pinned, :boolean, default: false
  field :race, :string
  field :alive, :boolean, default: true

  belongs_to :game, Game
  belongs_to :user, User

  timestamps(type: :utc_datetime)
end

def changeset(character, attrs, user_scope, game_id) do
  character
  |> cast(attrs, [
    :name,
    :content,
    :content_plain_text,
    :visibility,  # Add to cast
    :class,
    :level,
    :tags,
    :pinned,
    :race,
    :alive
  ])
  |> validate_required([:name, :class, :level])
  |> validate_inclusion(:visibility, ["private", "viewable", "editable"])
  |> put_change(:user_id, user_scope.user.id)
  |> put_change(:game_id, game_id)
end

# Apply similar changes to:
# - lib/game_master_core/factions/faction.ex
# - lib/game_master_core/locations/location.ex
# - lib/game_master_core/quests/quest.ex
# - lib/game_master_core/notes/note.ex
```

### 3. Create Entity Shares Table

**Migration:**

```elixir
# priv/repo/migrations/XXXXXX_create_entity_shares.exs
defmodule GameMasterCore.Repo.Migrations.CreateEntityShares do
  use Ecto.Migration

  def change do
    create table(:entity_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Polymorphic entity reference
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false

      # User being granted access
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      # Permission level: "editor", "viewer", "blocked"
      add :permission, :string, null: false

      # Who granted this permission (for audit trail)
      add :shared_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # Indexes for performance
    create index(:entity_shares, [:entity_type, :entity_id])
    create index(:entity_shares, [:user_id])
    create unique_index(:entity_shares, [:entity_type, :entity_id, :user_id])
  end
end
```

**Schema:**

```elixir
# lib/game_master_core/entity_shares/entity_share.ex
defmodule GameMasterCore.EntityShares.EntityShare do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @entity_types ["character", "faction", "location", "quest", "note"]
  @permissions ["editor", "viewer", "blocked"]

  schema "entity_shares" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :permission, :string

    belongs_to :user, User
    belongs_to :shared_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(share, attrs) do
    share
    |> cast(attrs, [:entity_type, :entity_id, :user_id, :permission, :shared_by_id])
    |> validate_required([:entity_type, :entity_id, :user_id, :permission])
    |> validate_inclusion(:entity_type, @entity_types)
    |> validate_inclusion(:permission, @permissions)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:shared_by_id)
    |> unique_constraint([:entity_type, :entity_id, :user_id])
  end
end
```

---

## Implementation Details

### 1. Authorization Module

```elixir
# lib/game_master_core/authorization.ex
defmodule GameMasterCore.Authorization do
  @moduledoc """
  Hybrid RBAC + ACL authorization for games and entities.

  Two-layer permission system:
  1. Role-based game-level permissions (Admin, Game Master, Member)
  2. Entity-level access control lists (visibility + explicit shares)
  """

  import Ecto.Query
  alias GameMasterCore.Repo
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games.{Game, GameMembership}
  alias GameMasterCore.EntityShares.EntityShare

  @type action :: :view | :edit | :delete
  @type entity :: struct()

  # ------------------------------------------------------------
  # Game-Level Permissions (RBAC)
  # ------------------------------------------------------------

  @doc """
  Check if scope has permission for game-level actions.

  ## Permissions
  - :manage_game - Modify game settings, delete game
  - :manage_members - Add/remove members, change roles
  """
  def authorized?(%Scope{game: nil}, _permission), do: false

  def authorized?(%Scope{user: user, game: game}, permission) do
    role = get_user_role(user.id, game)
    has_game_permission?(role, permission)
  end

  defp has_game_permission?(:admin, _), do: true
  defp has_game_permission?(:game_master, :manage_game), do: false
  defp has_game_permission?(:game_master, :manage_members), do: false
  defp has_game_permission?(:game_master, _), do: true
  defp has_game_permission?(:member, _), do: false
  defp has_game_permission?(_, _), do: false

  # ------------------------------------------------------------
  # Entity-Level Permissions (ACL)
  # ------------------------------------------------------------

  @doc """
  Check if user can perform action on entity.

  ## Actions
  - :view - Read entity data
  - :edit - Modify entity data
  - :delete - Remove entity

  ## Resolution Order
  1. Admin/Game Master role bypass (always allow)
  2. Explicit entity shares (blocked/editor/viewer)
  3. Entity ownership check
  4. Global visibility setting
  """
  def can_access_entity?(%Scope{user: user, game: game}, entity, action)
      when action in [:view, :edit, :delete] do
    role = get_user_role(user.id, game)

    # Admins and Game Masters bypass all entity permissions
    if role in [:admin, :game_master] do
      true
    else
      check_member_entity_access(user.id, entity, action)
    end
  end

  defp check_member_entity_access(user_id, entity, action) do
    entity_type = entity_type_from_struct(entity)

    # 1. Check explicit shares first
    case get_entity_share(entity_type, entity.id, user_id) do
      %{permission: "blocked"} ->
        false

      %{permission: "editor"} ->
        true

      %{permission: "viewer"} ->
        action == :view

      nil ->
        # 2. Check if user is creator
        if entity.user_id == user_id do
          true
        else
          # 3. Check global visibility
          check_global_visibility(entity.visibility, action)
        end
    end
  end

  defp check_global_visibility("editable", _action), do: true
  defp check_global_visibility("viewable", :view), do: true
  defp check_global_visibility("viewable", _), do: false
  defp check_global_visibility("private", _), do: false
  defp check_global_visibility(_, _), do: false

  # ------------------------------------------------------------
  # Entity Sharing Management
  # ------------------------------------------------------------

  @doc """
  Share an entity with a user.
  Only the entity creator, admins, or game masters can share.
  """
  def share_entity(%Scope{} = scope, entity, target_user_id, permission) do
    if can_share_entity?(scope, entity) do
      entity_type = entity_type_from_struct(entity)

      attrs = %{
        entity_type: entity_type,
        entity_id: entity.id,
        user_id: target_user_id,
        permission: permission,
        shared_by_id: scope.user.id
      }

      %EntityShare{}
      |> EntityShare.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:permission, :shared_by_id, :updated_at]},
        conflict_target: [:entity_type, :entity_id, :user_id]
      )
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Remove a share for an entity.
  Only the entity creator, admins, or game masters can unshare.
  """
  def unshare_entity(%Scope{} = scope, entity, target_user_id) do
    if can_share_entity?(scope, entity) do
      entity_type = entity_type_from_struct(entity)

      case Repo.get_by(EntityShare,
        entity_type: entity_type,
        entity_id: entity.id,
        user_id: target_user_id
      ) do
        nil -> {:error, :not_found}
        share -> Repo.delete(share)
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  List all shares for an entity.
  Only users who can view the entity can see its shares.
  """
  def list_entity_shares(%Scope{} = scope, entity) do
    if can_access_entity?(scope, entity, :view) do
      entity_type = entity_type_from_struct(entity)

      from(s in EntityShare,
        join: u in assoc(s, :user),
        where: s.entity_type == ^entity_type and s.entity_id == ^entity.id,
        select: %{
          user: u,
          permission: s.permission,
          shared_at: s.inserted_at
        }
      )
      |> Repo.all()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Update entity visibility.
  Only creator, admins, or game masters can change visibility.
  """
  def update_entity_visibility(%Scope{} = scope, entity, new_visibility) do
    role = get_user_role(scope.user.id, scope.game)

    if role in [:admin, :game_master] or entity.user_id == scope.user.id do
      {:ok, new_visibility}
    else
      {:error, :unauthorized}
    end
  end

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

  defp can_share_entity?(%Scope{user: user, game: game}, entity) do
    role = get_user_role(user.id, game)
    role in [:admin, :game_master] or entity.user_id == user.id
  end

  defp get_user_role(user_id, %Game{owner_id: owner_id}) when user_id == owner_id do
    :admin
  end

  defp get_user_role(user_id, %Game{id: game_id}) do
    case Repo.get_by(GameMembership, user_id: user_id, game_id: game_id) do
      nil -> nil
      %{role: "admin"} -> :admin
      %{role: "game_master"} -> :game_master
      %{role: "member"} -> :member
      %{role: "owner"} -> :admin  # Backward compatibility
    end
  end

  defp get_entity_share(entity_type, entity_id, user_id) do
    Repo.get_by(EntityShare,
      entity_type: entity_type,
      entity_id: entity_id,
      user_id: user_id
    )
  end

  defp entity_type_from_struct(%GameMasterCore.Characters.Character{}), do: "character"
  defp entity_type_from_struct(%GameMasterCore.Factions.Faction{}), do: "faction"
  defp entity_type_from_struct(%GameMasterCore.Locations.Location{}), do: "location"
  defp entity_type_from_struct(%GameMasterCore.Quests.Quest{}), do: "quest"
  defp entity_type_from_struct(%GameMasterCore.Notes.Note{}), do: "note"
end
```

### 2. Update Scope Module

```elixir
# lib/game_master_core/accounts/scope.ex
defmodule GameMasterCore.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  Enhanced to include role information for authorization decisions.
  """

  alias GameMasterCore.Accounts.User
  alias GameMasterCore.Games.{Game, GameMembership}

  defstruct user: nil, game: nil, role: nil  # Added role field

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Adds game context to scope and determines user's role in that game.
  """
  def put_game(%__MODULE__{user: user} = scope, %Game{} = game) do
    role = determine_role(user.id, game)
    %{scope | game: game, role: role}
  end

  defp determine_role(user_id, %Game{owner_id: owner_id}) when user_id == owner_id do
    :admin
  end

  defp determine_role(user_id, %Game{id: game_id}) do
    case GameMasterCore.Repo.get_by(GameMembership, user_id: user_id, game_id: game_id) do
      nil -> nil
      %{role: "admin"} -> :admin
      %{role: "game_master"} -> :game_master
      %{role: "member"} -> :member
      %{role: "owner"} -> :admin  # Backward compatibility
    end
  end
end
```

### 3. Update Entity Contexts

Apply to all entity context modules (Characters, Factions, Locations, Quests, Notes):

```elixir
# lib/game_master_core/characters.ex (example - apply to all entity contexts)

alias GameMasterCore.Authorization

@doc """
Update a character.
Checks authorization before allowing edit.
"""
def update_character(%Scope{} = scope, %Character{} = character, attrs) do
  if Authorization.can_access_entity?(scope, character, :edit) do
    with {:ok, character = %Character{}} <-
           character
           |> Character.changeset(attrs, scope, character.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, character})
      {:ok, character}
    end
  else
    {:error, :unauthorized}
  end
end

@doc """
Delete a character.
Checks authorization before allowing deletion.
"""
def delete_character(%Scope{} = scope, %Character{} = character) do
  if Authorization.can_access_entity?(scope, character, :delete) do
    Repo.transaction(fn ->
      case Images.delete_images_for_entity(scope, "character", character.id) do
        {:ok, _count} ->
          case Repo.delete(character) do
            {:ok, character} ->
              broadcast(scope, {:deleted, character})
              character
            {:error, reason} -> Repo.rollback(reason)
          end
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  else
    {:error, :unauthorized}
  end
end

@doc """
List characters for a game.
Filters to only characters the user has permission to view.
"""
def list_characters_for_game(%Scope{} = scope) do
  role = scope.role
  user_id = scope.user.id
  game_id = scope.game.id

  if role in [:admin, :game_master] do
    # Admin/GM: simple query, all entities
    from(c in Character, where: c.game_id == ^game_id)
    |> Repo.all()
  else
    # Member: complex query with visibility + shares
    from(c in Character,
      left_join: s in EntityShare,
      on: s.entity_type == "character" and s.entity_id == c.id and s.user_id == ^user_id,
      where: c.game_id == ^game_id,
      where: c.user_id == ^user_id or  # Own entities
             c.visibility in ["viewable", "editable"] or  # Public entities
             (not is_nil(s.id) and s.permission != "blocked")  # Explicit shares
    )
    |> Repo.all()
  end
end

@doc """
Update character visibility.
Only creator or elevated roles can change visibility.
"""
def update_character_visibility(%Scope{} = scope, %Character{} = character, visibility) do
  with {:ok, _} <- Authorization.update_entity_visibility(scope, character, visibility),
       {:ok, character} <-
         character
         |> Ecto.Changeset.change(visibility: visibility)
         |> Repo.update() do
    broadcast(scope, {:updated, character})
    {:ok, character}
  end
end

# Sharing functions - delegate to Authorization module
defdelegate share_character(scope, character, user_id, permission),
  to: Authorization, as: :share_entity

defdelegate unshare_character(scope, character, user_id),
  to: Authorization, as: :unshare_entity

defdelegate list_character_shares(scope, character),
  to: Authorization, as: :list_entity_shares
```

### 4. Update Games Context

```elixir
# lib/game_master_core/games.ex

alias GameMasterCore.Authorization

@doc """
Change a member's role in the game.
Only admins can change roles.
"""
def change_member_role(%Scope{} = scope, %Game{} = game, user_id, new_role) do
  if Authorization.authorized?(scope, :manage_members) do
    case Repo.get_by(GameMembership, game_id: game.id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      membership when membership.role == "admin" ->
        {:error, :cannot_change_admin_role}

      membership ->
        membership
        |> GameMembership.changeset(%{role: new_role})
        |> Repo.update()
    end
  else
    {:error, :unauthorized}
  end
end

@doc """
Add a member to the game.
Only admins can add members.
"""
def add_member(%Scope{} = scope, %Game{} = game, user_id, role \\ "member") do
  if Authorization.authorized?(scope, :manage_members) do
    attrs = %{game_id: game.id, user_id: user_id, role: role}

    %GameMembership{}
    |> GameMembership.changeset(attrs)
    |> Repo.insert()
  else
    {:error, :unauthorized}
  end
end

@doc """
Update game settings.
Only admins can modify game.
"""
def update_game(%Scope{} = scope, %Game{} = game, attrs) do
  if Authorization.authorized?(scope, :manage_game) do
    with {:ok, game = %Game{}} <-
           game
           |> Game.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, game})
      {:ok, game}
    end
  else
    {:error, :unauthorized}
  end
end

@doc """
Delete a game.
Only admins can delete games.
"""
def delete_game(%Scope{} = scope, %Game{} = game) do
  if Authorization.authorized?(scope, :manage_game) do
    with {:ok, game = %Game{}} <-
           Repo.delete(game) do
      broadcast(scope, {:deleted, game})
      {:ok, game}
    end
  else
    {:error, :unauthorized}
  end
end
```

---

## API Endpoints

### Entity Sharing Endpoints

Add to each entity controller (Characters, Factions, Locations, Quests, Notes):

```elixir
# lib/game_master_core_web/controllers/character_controller.ex (example)

@doc """
POST /api/games/:game_id/characters/:character_id/share

Share a character with another user.

Request Body:
{
  "user_id": "uuid",
  "permission": "editor" | "viewer" | "blocked"
}
"""
def share(conn, %{
  "game_id" => game_id,
  "character_id" => character_id,
  "user_id" => user_id,
  "permission" => permission
}) do
  scope = conn.assigns.current_scope

  with {:ok, game} <- Games.fetch_game(scope, game_id),
       scope <- Scope.put_game(scope, game),
       {:ok, character} <- Characters.fetch_character_for_game(scope, character_id),
       {:ok, _share} <- Characters.share_character(scope, character, user_id, permission) do
    conn
    |> put_status(:ok)
    |> json(%{success: true})
  end
end

@doc """
DELETE /api/games/:game_id/characters/:character_id/share/:user_id

Remove a share for a character.
"""
def unshare(conn, %{
  "game_id" => game_id,
  "character_id" => character_id,
  "user_id" => user_id
}) do
  scope = conn.assigns.current_scope

  with {:ok, game} <- Games.fetch_game(scope, game_id),
       scope <- Scope.put_game(scope, game),
       {:ok, character} <- Characters.fetch_character_for_game(scope, character_id),
       {:ok, _} <- Characters.unshare_character(scope, character, user_id) do
    conn
    |> put_status(:ok)
    |> json(%{success: true})
  end
end

@doc """
GET /api/games/:game_id/characters/:character_id/shares

List all users this character is shared with.
"""
def list_shares(conn, %{"game_id" => game_id, "character_id" => character_id}) do
  scope = conn.assigns.current_scope

  with {:ok, game} <- Games.fetch_game(scope, game_id),
       scope <- Scope.put_game(scope, game),
       {:ok, character} <- Characters.fetch_character_for_game(scope, character_id),
       {:ok, shares} <- Characters.list_character_shares(scope, character) do
    conn
    |> put_status(:ok)
    |> json(%{data: shares})
  end
end

@doc """
PATCH /api/games/:game_id/characters/:character_id/visibility

Update character visibility setting.

Request Body:
{
  "visibility": "private" | "viewable" | "editable"
}
"""
def update_visibility(conn, %{
  "game_id" => game_id,
  "character_id" => character_id,
  "visibility" => visibility
}) do
  scope = conn.assigns.current_scope

  with {:ok, game} <- Games.fetch_game(scope, game_id),
       scope <- Scope.put_game(scope, game),
       {:ok, character} <- Characters.fetch_character_for_game(scope, character_id),
       {:ok, character} <- Characters.update_character_visibility(scope, character, visibility) do
    conn
    |> put_status(:ok)
    |> json(%{
      data: %{
        id: character.id,
        visibility: character.visibility
      }
    })
  end
end
```

### Game Member Management Endpoints

```elixir
# lib/game_master_core_web/controllers/game_controller.ex

@doc """
PATCH /api/games/:game_id/members/:user_id/role

Change a member's role.

Request Body:
{
  "role": "admin" | "game_master" | "member"
}
"""
def update_member_role(conn, %{
  "game_id" => game_id,
  "user_id" => user_id,
  "role" => role
}) do
  scope = conn.assigns.current_scope

  with {:ok, game} <- Games.fetch_game(scope, game_id),
       scope <- Scope.put_game(scope, game),
       {:ok, membership} <- Games.change_member_role(scope, game, user_id, role) do
    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      data: %{
        user_id: membership.user_id,
        game_id: membership.game_id,
        role: membership.role
      }
    })
  end
end
```

### Enhanced JSON Responses

Update JSON views to include role and visibility information:

```elixir
# lib/game_master_core_web/controllers/game_json.ex

def show(%{game: game, scope: scope}) do
  %{
    data: %{
      id: game.id,
      name: game.name,
      content: game.content,
      setting: game.setting,
      owner_id: game.owner_id,
      your_role: scope.role,  # NEW: Include user's role
      inserted_at: game.inserted_at,
      updated_at: game.updated_at
    }
  }
end

# lib/game_master_core_web/controllers/character_json.ex

def show(%{character: character, scope: scope}) do
  %{
    data: %{
      id: character.id,
      name: character.name,
      content: character.content,
      visibility: character.visibility,  # NEW: Include visibility
      can_edit: GameMasterCore.Authorization.can_access_entity?(scope, character, :edit),  # NEW
      can_delete: GameMasterCore.Authorization.can_access_entity?(scope, character, :delete),  # NEW
      # ... other fields ...
    }
  }
end
```

---

## Permission Matrix

### Complete Permission Matrix

| User Role | Game Settings | Manage Members | Own Entities | Others' Private | Others' Viewable | Others' Editable | Shared (Editor) | Shared (Viewer) | Shared (Blocked) |
|-----------|---------------|----------------|--------------|-----------------|------------------|------------------|-----------------|-----------------|------------------|
| **Admin** | ✅ Full | ✅ Full | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete |
| **Game Master** | ❌ No | ❌ No | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete | ✅ Edit/Delete |
| **Member** | ❌ No | ❌ No | ✅ Edit/Delete | ❌ No | 👁️ View | ✅ Edit/Delete | ✅ Edit/Delete | 👁️ View | ❌ No |

### Role Capabilities Summary

| Capability | Admin | Game Master | Member |
|------------|-------|-------------|--------|
| View all entities | ✅ | ✅ | ⚠️ Subject to ACL |
| Edit own entities | ✅ | ✅ | ✅ |
| Edit others' entities | ✅ | ✅ | ⚠️ Subject to ACL |
| Delete any entity | ✅ | ✅ | ⚠️ Only own |
| Share entities | ✅ | ✅ | ✅ Own only |
| Modify game settings | ✅ | ❌ | ❌ |
| Add/remove members | ✅ | ❌ | ❌ |
| Change member roles | ✅ | ❌ | ❌ |
| Delete game | ✅ | ❌ | ❌ |

---

## Migration & Rollout Strategy

### Phase 1: Schema Changes (Week 1)

**Goals:**
- Update database schema
- Maintain backward compatibility
- No disruption to existing games

**Tasks:**
1. Create migration for GameMembership role update
2. Create migrations for entity visibility fields (5 tables)
3. Create migration for entity_shares table
4. Run migrations in staging environment
5. Verify existing data integrity
6. Backfill existing entities with `visibility = "private"`

**Testing:**
- Verify migrations run cleanly
- Check existing games still load
- Confirm no data loss

### Phase 2: Authorization Layer (Week 2)

**Goals:**
- Implement core authorization logic
- Update Scope module
- Comprehensive unit tests

**Tasks:**
1. Create `lib/game_master_core/authorization.ex`
2. Create `lib/game_master_core/entity_shares/entity_share.ex`
3. Update `lib/game_master_core/accounts/scope.ex`
4. Write comprehensive unit tests for Authorization module
5. Test all permission combinations

**Testing:**
- Unit tests for all authorization scenarios
- Test role resolution logic
- Test entity permission resolution
- Test sharing logic

### Phase 3: Context Updates (Week 3)

**Goals:**
- Integrate authorization into all contexts
- Update entity schemas
- Add sharing functions

**Tasks:**
1. Update Games context for role management
2. Update all entity contexts (Characters, Factions, Locations, Quests, Notes)
3. Add visibility field to all entity schemas
4. Add sharing delegation functions
5. Update list queries for permission filtering
6. Integration tests for each context

**Testing:**
- Integration tests for Games context
- Integration tests for each entity context
- Test permission enforcement
- Test unauthorized access denials

### Phase 4: API & Responses (Week 4)

**Goals:**
- Expose sharing functionality via API
- Update JSON responses
- Add role management endpoints

**Tasks:**
1. Add sharing endpoints to all entity controllers
2. Add role management endpoints to game controller
3. Update JSON views to include role/visibility info
4. Update API documentation
5. E2E tests for all new endpoints

**Testing:**
- E2E tests for sharing workflows
- E2E tests for role management
- Test API error responses
- Test unauthorized API access

### Phase 5: Documentation & Monitoring (Week 5)

**Goals:**
- Complete documentation
- Performance monitoring
- Production deployment

**Tasks:**
1. Write user-facing documentation
2. Write developer documentation
3. Create admin guides for role management
4. Set up monitoring for authorization performance
5. Deploy to production with feature flag
6. Monitor for issues

**Testing:**
- Performance testing with production-like data
- Load testing permission checks
- Monitor query performance

---

## Performance Considerations

### Query Optimization

#### Entity List Filtering

**Problem:** Naive approach loads all entities then filters in memory

**Solution:** Build SQL queries that filter at database level

```elixir
def list_characters_for_game(%Scope{} = scope) do
  role = scope.role
  user_id = scope.user.id
  game_id = scope.game.id

  if role in [:admin, :game_master] do
    # Simple query for elevated roles
    from(c in Character, where: c.game_id == ^game_id)
    |> Repo.all()
  else
    # Complex query for members with ACL filtering
    from(c in Character,
      left_join: s in EntityShare,
      on: s.entity_type == "character" and
         s.entity_id == c.id and
         s.user_id == ^user_id,
      where: c.game_id == ^game_id,
      where:
        # Own entities
        c.user_id == ^user_id or
        # Public entities (not blocked)
        (c.visibility in ["viewable", "editable"] and
         (is_nil(s.id) or s.permission != "blocked")) or
        # Explicitly shared (not blocked)
        (not is_nil(s.id) and s.permission in ["editor", "viewer"])
    )
    |> Repo.all()
  end
end
```

#### Share Lookup Optimization

**Problem:** N+1 queries when checking permissions for multiple entities

**Solution:** Batch load shares for multiple entities

```elixir
def preload_shares(entities, user_id) do
  entity_ids = Enum.map(entities, & &1.id)
  entity_type = entity_type_from_struct(hd(entities))

  shares = from(s in EntityShare,
    where: s.entity_type == ^entity_type and
           s.entity_id in ^entity_ids and
           s.user_id == ^user_id
  )
  |> Repo.all()
  |> Map.new(fn share -> {share.entity_id, share} end)

  Enum.map(entities, fn entity ->
    Map.put(entity, :__share__, Map.get(shares, entity.id))
  end)
end
```

### Caching Considerations

**Role Caching:**
- User role in game is already cached in Scope
- No additional caching needed

**Entity Shares:**
- Consider ETS cache for frequently-accessed shares
- Cache invalidation on share create/update/delete
- Key: `{entity_type, entity_id, user_id}`

**Example ETS Cache:**
```elixir
defmodule GameMasterCore.ShareCache do
  def get(entity_type, entity_id, user_id) do
    case :ets.lookup(:share_cache, {entity_type, entity_id, user_id}) do
      [{_key, share}] -> share
      [] -> nil
    end
  end

  def put(entity_type, entity_id, user_id, share) do
    :ets.insert(:share_cache, {{entity_type, entity_id, user_id}, share})
  end

  def invalidate(entity_type, entity_id, user_id) do
    :ets.delete(:share_cache, {entity_type, entity_id, user_id})
  end
end
```

### Database Indexes

Ensure these indexes exist:

```elixir
# Already created in migrations:
create index(:entity_shares, [:entity_type, :entity_id])
create index(:entity_shares, [:user_id])
create unique_index(:entity_shares, [:entity_type, :entity_id, :user_id])

# Entity visibility indexes:
create index(:characters, [:visibility])
create index(:factions, [:visibility])
create index(:locations, [:visibility])
create index(:quests, [:visibility])
create index(:notes, [:visibility])

# Game membership indexes (likely already exist):
create index(:game_members, [:game_id])
create index(:game_members, [:user_id])
```

---

## Testing Strategy

### Unit Tests

#### Authorization Module Tests

```elixir
# test/game_master_core/authorization_test.exs
defmodule GameMasterCore.AuthorizationTest do
  use GameMasterCore.DataCase

  import GameMasterCore.{AccountsFixtures, GamesFixtures, CharactersFixtures}

  describe "authorized?/2 - game-level permissions" do
    setup do
      admin = user_fixture()
      game_master = user_fixture()
      member = user_fixture()
      game = game_fixture(owner: admin)

      # Add members with different roles
      add_member(game, game_master, "game_master")
      add_member(game, member, "member")

      %{
        admin: admin,
        game_master: game_master,
        member: member,
        game: game
      }
    end

    test "admin has all game permissions", %{admin: admin, game: game} do
      scope = Scope.for_user(admin) |> Scope.put_game(game)

      assert Authorization.authorized?(scope, :manage_game)
      assert Authorization.authorized?(scope, :manage_members)
    end

    test "game master cannot manage game or members", %{game_master: gm, game: game} do
      scope = Scope.for_user(gm) |> Scope.put_game(game)

      refute Authorization.authorized?(scope, :manage_game)
      refute Authorization.authorized?(scope, :manage_members)
    end

    test "member has no game permissions", %{member: member, game: game} do
      scope = Scope.for_user(member) |> Scope.put_game(game)

      refute Authorization.authorized?(scope, :manage_game)
      refute Authorization.authorized?(scope, :manage_members)
    end
  end

  describe "can_access_entity?/3 - entity permissions" do
    setup do
      admin = user_fixture()
      game_master = user_fixture()
      member1 = user_fixture()
      member2 = user_fixture()
      game = game_fixture(owner: admin)

      add_member(game, game_master, "game_master")
      add_member(game, member1, "member")
      add_member(game, member2, "member")

      scope1 = Scope.for_user(member1) |> Scope.put_game(game)
      private_char = character_fixture(scope: scope1, visibility: "private")
      viewable_char = character_fixture(scope: scope1, visibility: "viewable")
      editable_char = character_fixture(scope: scope1, visibility: "editable")

      %{
        admin: admin,
        game_master: game_master,
        member1: member1,
        member2: member2,
        game: game,
        private_char: private_char,
        viewable_char: viewable_char,
        editable_char: editable_char
      }
    end

    test "admin can access all entities", context do
      scope = Scope.for_user(context.admin) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope, context.private_char, :view)
      assert Authorization.can_access_entity?(scope, context.private_char, :edit)
      assert Authorization.can_access_entity?(scope, context.viewable_char, :edit)
      assert Authorization.can_access_entity?(scope, context.editable_char, :edit)
    end

    test "game master can access all entities", context do
      scope = Scope.for_user(context.game_master) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope, context.private_char, :view)
      assert Authorization.can_access_entity?(scope, context.private_char, :edit)
      assert Authorization.can_access_entity?(scope, context.viewable_char, :edit)
      assert Authorization.can_access_entity?(scope, context.editable_char, :edit)
    end

    test "member can access own entities", context do
      scope = Scope.for_user(context.member1) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope, context.private_char, :view)
      assert Authorization.can_access_entity?(scope, context.private_char, :edit)
      assert Authorization.can_access_entity?(scope, context.private_char, :delete)
    end

    test "member cannot access others' private entities", context do
      scope = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      refute Authorization.can_access_entity?(scope, context.private_char, :view)
      refute Authorization.can_access_entity?(scope, context.private_char, :edit)
    end

    test "member can view others' viewable entities", context do
      scope = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope, context.viewable_char, :view)
      refute Authorization.can_access_entity?(scope, context.viewable_char, :edit)
    end

    test "member can edit others' editable entities", context do
      scope = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope, context.editable_char, :view)
      assert Authorization.can_access_entity?(scope, context.editable_char, :edit)
    end
  end

  describe "share_entity/4 - explicit sharing" do
    setup do
      member1 = user_fixture()
      member2 = user_fixture()
      game = game_fixture()

      add_member(game, member1, "member")
      add_member(game, member2, "member")

      scope1 = Scope.for_user(member1) |> Scope.put_game(game)
      private_char = character_fixture(scope: scope1, visibility: "private")

      %{
        member1: member1,
        member2: member2,
        game: game,
        scope1: scope1,
        private_char: private_char
      }
    end

    test "creator can share their entity", context do
      assert {:ok, _share} = Authorization.share_entity(
        context.scope1,
        context.private_char,
        context.member2.id,
        "editor"
      )
    end

    test "shared user gains access", context do
      {:ok, _share} = Authorization.share_entity(
        context.scope1,
        context.private_char,
        context.member2.id,
        "editor"
      )

      scope2 = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope2, context.private_char, :view)
      assert Authorization.can_access_entity?(scope2, context.private_char, :edit)
    end

    test "viewer permission grants view only", context do
      {:ok, _share} = Authorization.share_entity(
        context.scope1,
        context.private_char,
        context.member2.id,
        "viewer"
      )

      scope2 = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      assert Authorization.can_access_entity?(scope2, context.private_char, :view)
      refute Authorization.can_access_entity?(scope2, context.private_char, :edit)
    end

    test "blocked permission denies access", context do
      # First make entity viewable
      Ecto.Changeset.change(context.private_char, visibility: "viewable")
      |> Repo.update!()

      {:ok, _share} = Authorization.share_entity(
        context.scope1,
        context.private_char,
        context.member2.id,
        "blocked"
      )

      scope2 = Scope.for_user(context.member2) |> Scope.put_game(context.game)

      refute Authorization.can_access_entity?(scope2, context.private_char, :view)
    end
  end
end
```

### Integration Tests

```elixir
# test/game_master_core/characters_test.exs
defmodule GameMasterCore.CharactersTest do
  use GameMasterCore.DataCase

  describe "update_character/3 with authorization" do
    test "member can update own character" do
      # Setup and test
    end

    test "member cannot update others' private character" do
      # Setup and test unauthorized access
    end

    test "game master can update any character" do
      # Setup and test elevated permissions
    end
  end

  describe "list_characters_for_game/1 with visibility" do
    test "admin sees all characters" do
      # Setup and test
    end

    test "member sees only accessible characters" do
      # Setup: create private, viewable, editable characters
      # Test: member only sees viewable, editable, and own
    end
  end
end
```

### API Tests

```elixir
# test/game_master_core_web/controllers/character_controller_test.exs
defmodule GameMasterCoreWeb.CharacterControllerTest do
  use GameMasterCoreWeb.ConnCase

  describe "POST /api/games/:game_id/characters/:id/share" do
    test "creator can share character with viewer permission", %{conn: conn} do
      # Create game, character, users
      # Test successful share
      # Verify response
    end

    test "non-creator cannot share others' characters", %{conn: conn} do
      # Setup
      # Test 403 unauthorized
    end

    test "shared user can view but not edit with viewer permission", %{conn: conn} do
      # Share with viewer permission
      # Test GET works
      # Test PATCH fails
    end
  end

  describe "PATCH /api/games/:game_id/characters/:id/visibility" do
    test "creator can change visibility", %{conn: conn} do
      # Test successful visibility change
    end

    test "non-creator cannot change visibility", %{conn: conn} do
      # Test 403 unauthorized
    end
  end
end
```

---

## Open Questions & Decisions

### 1. Default Visibility ✅ DECIDED
**Question:** Should new entities default to "private" or "viewable"?

**Decision:** **Private** - All new entities default to private visibility for security.

### 2. Batch Sharing ✅ DECIDED
**Question:** Do we need bulk share operations?

**Decision:** **Skip for now** - Not implementing initially. Should be easy to add later if users request it.

### 3. Share Notifications ✅ DECIDED
**Question:** Should users be notified when something is shared with them?

**Decision:** **Not yet** - No robust notification system in place. Defer to future implementation.

### 4. Share Expiration ✅ DECIDED
**Question:** Do we need time-limited shares?

**Decision:** **No** - Manual unshare only. No time-based expiration needed.

### 5. Ownership Transfer ✅ DECIDED
**Question:** Can entity ownership be transferred between users?

**Decision:** **Yes** - Support ownership transfer via existing/adapted edit API by allowing `user_id` changes with proper authorization checks. Can be implemented using standard update endpoints.

### 6. Role Promotion ✅ DECIDED
**Question:** Can Admins promote Members directly to Admin, or only to Game Master?

**Decision:** **Full flexibility** - Admins can create other admins. No restrictions on role changes.

### 7. Multiple Admins ✅ DECIDED
**Question:** Should games support multiple Admins?

**Decision:** **Yes** - Support multiple admins per game via GameMembership roles. The `game.owner_id` field is still used for initial ownership determination, but additional admins can be added via role assignments.

### 8. Visibility Display ✅ DECIDED
**Question:** Should Admins/GMs be able to see that an entity is private?

**Decision:** **Yes** - Include visibility status in API responses for all users. Note: This project is API-only, frontend client is separate and will handle display.

---

## Conclusion

This proposal provides a comprehensive, two-layer authorization system that:

✅ **Maintains backward compatibility** with existing games
✅ **Minimal schema changes** (leverages existing `role` field)
✅ **Flexible and extensible** (can add new roles/permissions)
✅ **Performance-conscious** (optimized queries, caching strategy)
✅ **Well-tested** (comprehensive test strategy)
✅ **Clear migration path** (5-week phased rollout)

The hybrid RBAC + ACL approach provides:
- **Simple role-based permissions** for game-level actions
- **Fine-grained entity sharing** for collaborative workflows
- **Clear authorization resolution** logic
- **Audit trails** via timestamps and `shared_by_id`

Next steps:
1. Review and approve this proposal
2. Answer open questions
3. Create implementation tasks in backlog
4. Begin Phase 1 implementation

---

**End of Proposal**
