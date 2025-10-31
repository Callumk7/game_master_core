defmodule GameMasterCore.Authorization do
  @moduledoc """
  Hybrid RBAC + ACL authorization for games and entities.

  Two-layer permission system:
  1. Role-based game-level permissions (Admin, Game Master, Member)
  2. Entity-level access control lists (visibility + explicit shares)

  ## Roles

  - **Admin**: Full game management + all entity access
  - **Game Master**: All entity access, no game/member management
  - **Member**: Subject to entity-level permissions

  ## Entity Visibility

  - **private**: Only creator + admins/GMs can access
  - **viewable**: Anyone in game can view, only creator + admins/GMs can edit
  - **editable**: Anyone in game can view and edit

  ## Entity Shares

  Members can grant explicit permissions:
  - **editor**: User can view and edit
  - **viewer**: User can view only
  - **blocked**: User cannot access (even if viewable/editable)
  """

  import Ecto.Query
  alias GameMasterCore.Repo
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.EntityShares.EntityShare

  @type action :: :view | :edit | :delete
  @type entity :: struct()
  @type role :: :admin | :game_master | :member | nil

  # ------------------------------------------------------------
  # Game-Level Permissions (RBAC)
  # ------------------------------------------------------------

  @doc """
  Check if scope has permission for game-level actions.

  ## Permissions

  - `:manage_game` - Modify game settings, delete game
  - `:manage_members` - Add/remove members, change roles

  ## Examples

      iex> Authorization.authorized?(admin_scope, :manage_game)
      true

      iex> Authorization.authorized?(game_master_scope, :manage_game)
      false

      iex> Authorization.authorized?(member_scope, :manage_members)
      false

  ## Raises

  `ArgumentError` if scope does not have game context. Make sure to call
  `Scope.put_game/2` before checking game-level permissions.
  """
  @spec authorized?(Scope.t(), atom()) :: boolean()
  def authorized?(%Scope{game: nil}, _permission) do
    raise ArgumentError, """
    cannot check game-level permissions without game context.

    Make sure to call Scope.put_game/2 before checking permissions:

        scope = Scope.for_user(user)
        scope = Scope.put_game(scope, game)
        Authorization.authorized?(scope, :manage_game)
    """
  end

  def authorized?(%Scope{role: role}, permission) do
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

  - `:view` - Read entity data
  - `:edit` - Modify entity data
  - `:delete` - Remove entity

  ## Resolution Order

  1. Admin/Game Master role bypass (always allow)
  2. Explicit entity shares (blocked/editor/viewer)
  3. Entity ownership check
  4. Global visibility setting

  ## Examples

      iex> Authorization.can_access_entity?(admin_scope, private_entity, :edit)
      true

      iex> Authorization.can_access_entity?(member_scope, own_entity, :edit)
      true

      iex> Authorization.can_access_entity?(member_scope, others_private_entity, :view)
      false
  """
  @spec can_access_entity?(Scope.t(), entity(), action()) :: boolean()
  def can_access_entity?(%Scope{user: user, role: role}, entity, action)
      when action in [:view, :edit, :delete] do
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

  ## Parameters

  - `scope` - Scope with user and game context
  - `entity` - The entity to share
  - `target_user_id` - UUID of user receiving access
  - `permission` - "editor", "viewer", or "blocked"

  ## Returns

  - `{:ok, share}` - Share created/updated
  - `{:error, :unauthorized}` - User cannot share this entity
  - `{:error, changeset}` - Validation errors

  ## Examples

      iex> Authorization.share_entity(creator_scope, character, other_user_id, "editor")
      {:ok, %EntityShare{}}

      iex> Authorization.share_entity(non_creator_scope, character, user_id, "editor")
      {:error, :unauthorized}
  """
  @spec share_entity(Scope.t(), entity(), String.t(), String.t()) ::
          {:ok, EntityShare.t()} | {:error, :unauthorized | Ecto.Changeset.t()}
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
        on_conflict: {:replace, [:permission, :shared_by_id, :inserted_at, :updated_at]},
        conflict_target: [:entity_type, :entity_id, :user_id]
      )
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Remove a share for an entity.

  Only the entity creator, admins, or game masters can unshare.

  ## Examples

      iex> Authorization.unshare_entity(creator_scope, character, user_id)
      {:ok, %EntityShare{}}

      iex> Authorization.unshare_entity(creator_scope, character, nonexistent_user_id)
      {:error, :not_found}
  """
  @spec unshare_entity(Scope.t(), entity(), String.t()) ::
          {:ok, EntityShare.t()} | {:error, :unauthorized | :not_found}
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

  ## Returns

  - `{:ok, shares}` - List of share records with user info
  - `{:error, :unauthorized}` - User cannot view this entity

  ## Examples

      iex> Authorization.list_entity_shares(creator_scope, character)
      {:ok, [%{user: %User{}, permission: "editor", shared_at: ~U[...]}]}
  """
  @spec list_entity_shares(Scope.t(), entity()) ::
          {:ok, list(map())} | {:error, :unauthorized}
  def list_entity_shares(%Scope{} = scope, entity) do
    if can_access_entity?(scope, entity, :view) do
      entity_type = entity_type_from_struct(entity)

      shares =
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

      {:ok, shares}
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Update entity visibility.

  Only creator, admins, or game masters can change visibility.

  ## Examples

      iex> Authorization.update_entity_visibility(creator_scope, entity, "viewable")
      {:ok, "viewable"}

      iex> Authorization.update_entity_visibility(member_scope, others_entity, "viewable")
      {:error, :unauthorized}
  """
  @spec update_entity_visibility(Scope.t(), entity(), String.t()) ::
          {:ok, String.t()} | {:error, :unauthorized}
  def update_entity_visibility(%Scope{user: user, role: role}, entity, new_visibility) do
    if role in [:admin, :game_master] or entity.user_id == user.id do
      {:ok, new_visibility}
    else
      {:error, :unauthorized}
    end
  end

  # ------------------------------------------------------------
  # Query Helpers for Context Functions
  # ------------------------------------------------------------

  @doc """
  Build a query to filter entities based on user's permissions.

  For admins/game masters: returns all entities in game.
  For members: filters to only accessible entities (own, viewable, editable, shared).

  This is useful for list operations where you need to efficiently filter
  at the database level rather than loading all and filtering in memory.

  ## Examples

      iex> query = from(c in Character, where: c.game_id == ^game_id)
      iex> Authorization.scope_entity_query(query, Character, scope)
      #Ecto.Query<...>
  """
  @spec scope_entity_query(Ecto.Query.t(), module(), Scope.t()) :: Ecto.Query.t()
  def scope_entity_query(query, _entity_module, %Scope{role: role})
      when role in [:admin, :game_master] do
    # Admin/GM: no filtering needed, return query as-is
    query
  end

  def scope_entity_query(query, entity_module, %Scope{user: user}) do
    entity_type = entity_type_from_module(entity_module)
    user_id = user.id

    # Member: complex filtering with visibility + shares
    from(e in query,
      left_join: s in EntityShare,
      on:
        s.entity_type == ^entity_type and
          s.entity_id == e.id and
          s.user_id == ^user_id,
      where:
        e.user_id == ^user_id or
          (e.visibility in ["viewable", "editable"] and
             (is_nil(s.id) or s.permission != "blocked")) or
          (not is_nil(s.id) and s.permission in ["editor", "viewer"]),
      distinct: true
    )
  end

  # ------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------

  defp can_share_entity?(%Scope{user: user, role: role}, entity) do
    role in [:admin, :game_master] or entity.user_id == user.id
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

  defp entity_type_from_module(GameMasterCore.Characters.Character), do: "character"
  defp entity_type_from_module(GameMasterCore.Factions.Faction), do: "faction"
  defp entity_type_from_module(GameMasterCore.Locations.Location), do: "location"
  defp entity_type_from_module(GameMasterCore.Quests.Quest), do: "quest"
  defp entity_type_from_module(GameMasterCore.Notes.Note), do: "note"
end
