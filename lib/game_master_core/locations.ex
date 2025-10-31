defmodule GameMasterCore.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false
  import GameMasterCore.Helpers

  alias GameMasterCore.Repo

  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Images
  alias GameMasterCore.Links
  alias GameMasterCore.Authorization

  @doc """
  Subscribes to scoped notifications about any location changes.

  The broadcasted messages match the pattern:

    * {:created, %Location{}}
    * {:updated, %Location{}}
    * {:deleted, %Location{}}

  """
  def subscribe_locations(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:locations")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:locations", message)
  end

  @doc """
  Returns the list of locations for a game.
  Filters locations based on user's permissions (role-based + entity-level).
  """
  def list_locations_for_game(%Scope{} = scope) do
    from(l in Location, where: l.game_id == ^scope.game.id)
    |> Authorization.scope_entity_query(Location, scope)
    |> Repo.all()
  end

  def get_location_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Location, id: id, game_id: scope.game.id)
  end

  @doc """
  Fetches a single location for a specific game.
  Only users who can access the game can access its locations.

  Returns `{:ok, location}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_location_for_game(%Scope{} = scope, id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get_by(Location, id: uuid, game_id: scope.game.id) do
          nil -> {:error, :not_found}
          location -> {:ok, location}
        end

      :error ->
        {:error, :not_found}
    end
  end

  def create_location_for_game(%Scope{} = scope, attrs) do
    with {:ok, location = %Location{}} <-
           %Location{}
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, location})
      {:ok, location}
    end
  end

  @doc """
  Creates a location and establishes links to other entities in a single transaction.

  Creates the location and establishes all specified relationships in a single transaction.
  Links are expected to be a list of maps with keys:
  - entity_type: "faction", "location", "note", "quest", or "character"
  - entity_id: UUID of the entity to link to
  - Additional metadata fields like is_primary, parent_location, etc.

  ## Examples

      iex> create_location_with_links(scope, %{name: "Rivendell"}, [
        %{entity_type: "character", entity_id: character_id, relationship_type: "home"}
      ])
      {:ok, %Location{}}
      
      iex> create_location_with_links(scope, %{invalid: "data"}, [])
      {:error, %Ecto.Changeset{}}
  """
  def create_location_with_links(%Scope{} = scope, attrs, links) when is_list(links) do
    Repo.transaction(fn ->
      with {:ok, location} <- create_location_for_game(scope, attrs),
           {:ok, {_links, updated_location}} <-
             create_links_for_location(scope, location, links) do
        updated_location
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Returns a hierarchical tree structure of locations for a game.

  ## Examples

      iex> list_locations_tree_for_game(scope)
      {:ok, [%{id: "...", name: "Continent", children: [%{id: "...", name: "City", children: []}]}]}

      iex> list_locations_tree_for_game(scope, start_id)
      {:ok, [%{id: "start_id", name: "Specific Location", children: [...]}]}

      iex> list_locations_tree_for_game(scope, "invalid-id")
      {:error, :not_found}

  """
  def list_locations_tree_for_game(%Scope{} = scope, start_id \\ nil) do
    locations =
      from(l in Location,
        where: l.game_id == ^scope.game.id,
        order_by: [asc: l.name]
      )
      |> Repo.all()

    case start_id do
      nil ->
        {:ok, build_tree(locations)}

      id ->
        case Enum.find(locations, fn l -> l.id == id end) do
          nil ->
            {:error, :not_found}

          location ->
            grouped = Enum.group_by(locations, & &1.parent_id)
            tree_node = build_location_node(location, grouped)
            {:ok, [tree_node]}
        end
    end
  end

  defp build_tree(locations) do
    # Group locations by parent_id
    grouped = Enum.group_by(locations, & &1.parent_id)

    # Start with root locations (parent_id is nil)
    root_locations = Map.get(grouped, nil, [])

    # Build tree recursively
    Enum.map(root_locations, fn location ->
      build_location_node(location, grouped)
    end)
  end

  defp build_location_node(location, grouped) do
    children =
      grouped
      |> Map.get(location.id, [])
      |> Enum.map(&build_location_node(&1, grouped))

    %{
      id: location.id,
      name: location.name,
      content: location.content,
      type: location.type,
      tags: location.tags,
      parent_id: location.parent_id,
      entity_type: "location",
      children: children
    }
  end

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations(scope)
      [%Location{}, ...]

  """
  def list_locations(%Scope{} = scope) do
    Repo.all_by(Location, user_id: scope.user.id)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(scope, 123)
      %Location{}

      iex> get_location!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(%Scope{} = scope, id) do
    Repo.get_by!(Location, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(scope, %{field: value})
      {:ok, %Location{}}

      iex> create_location(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(%Scope{} = scope, attrs) do
    game_id = Map.get(attrs, "game_id") || Map.get(attrs, :game_id)

    if game_id do
      with {:ok, location = %Location{}} <-
             %Location{}
             |> Location.changeset(attrs, scope, game_id)
             |> Repo.insert() do
        broadcast(scope, {:created, location})
        {:ok, location}
      end
    else
      {:error, :game_id_required}
    end
  end

  @doc """
  Updates a location.
  Checks authorization before allowing edit.

  ## Examples

      iex> update_location(scope, location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(scope, location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Scope{} = scope, %Location{} = location, attrs) do
    if Authorization.can_access_entity?(scope, location, :edit) do
      with {:ok, location = %Location{}} <-
             location
             |> Location.changeset(attrs, scope, location.game_id)
             |> Repo.update() do
        broadcast(scope, {:updated, location})
        {:ok, location}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a location.
  Checks authorization before allowing deletion.

  ## Examples

      iex> delete_location(scope, location)
      {:ok, %Location{}}

      iex> delete_location(scope, location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Scope{} = scope, %Location{} = location) do
    if Authorization.can_access_entity?(scope, location, :delete) do
      Repo.transaction(fn ->
        # First, delete all associated images
        case Images.delete_images_for_entity(scope, "location", location.id) do
          {:ok, _count} ->
            # Then delete the location
            case Repo.delete(location) do
              {:ok, location} ->
                broadcast(scope, {:deleted, location})
                location

              {:error, reason} ->
                Repo.rollback(reason)
            end

          {:error, reason} ->
            Repo.rollback(reason)
        end
      end)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(scope, location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Scope{} = scope, %Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs, scope, location.game_id)
  end

  ## Location Children

  @doc """
  Returns the list of children for a location.

  ## Examples

      iex> list_children(scope, location)
      [%Location{}, ...]

  """
  def list_children(%Scope{} = _scope, %Location{} = location) do
    Repo.all_by(Location, parent_id: location.id)
  end

  # Child location functions

  @doc """
  Creates a child location.

  ## Examples

      iex> create_child_location(scope, location, %{field: value})
      {:ok, %Location{}}

      iex> create_child_location(scope, location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_child_location(%Scope{} = scope, %Location{} = location, attrs) do
    with {:ok, child = %Location{}} <-
           %Location{}
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Location.put_parent(location)
           |> Repo.insert() do
      broadcast(scope, {:created, child})
      {:ok, child}
    end
  end

  @doc """
  Updates a child location.

  ## Examples

      iex> update_child_location(scope, location, child, %{field: new_value})
      {:ok, %Location{}}

      iex> update_child_location(scope, location, child, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_child_location(%Scope{} = scope, %Location{} = location, %Location{} = child, attrs) do
    with {:ok, child = %Location{}} <-
           child
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Location.put_parent(location)
           |> Repo.update() do
      broadcast(scope, {:updated, child})
      {:ok, child}
    end
  end

  @doc """
  Get all children for a location
  """
  def get_children(%Scope{} = _scope, %Location{} = location) do
    Repo.all_by(Location, parent_id: location.id)
  end

  ## Location Links

  @doc """
  Links a character to a location.
  """
  def link_character(%Scope{} = scope, location_id, character_id, metadata_attrs \\ %{}) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.link(location, character, metadata_attrs)
    end
  end

  @doc """
  Links a note to a location.
  """
  def link_note(%Scope{} = scope, location_id, note_id, metadata_attrs \\ %{}) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(location, note, metadata_attrs)
    end
  end

  @doc """
  Links a faction to a location.
  """
  def link_faction(%Scope{} = scope, location_id, faction_id, metadata_attrs \\ %{}) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(location, faction, metadata_attrs)
    end
  end

  @doc """
  Links a quest to a location.
  """
  def link_quest(%Scope{} = scope, location_id, quest_id, metadata_attrs \\ %{}) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.link(location, quest, metadata_attrs)
    end
  end

  @doc """
  Links a location to another location.
  """
  def link_location(%Scope{} = scope, location_id_1, location_id_2, metadata_attrs \\ %{}) do
    with {:ok, location_1} <- get_scoped_location(scope, location_id_1),
         {:ok, location_2} <- get_scoped_location(scope, location_id_2) do
      Links.link(location_1, location_2, metadata_attrs)
    end
  end

  @doc """
  Unlinks a character from a location.
  """
  def unlink_character(%Scope{} = scope, location_id, character_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(location, character)
    end
  end

  @doc """
  Unlinks a note from a location.
  """
  def unlink_note(%Scope{} = scope, location_id, note_id) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(location, note)
    end
  end

  @doc """
  Unlinks a faction from a location.
  """
  def unlink_faction(%Scope{} = scope, location_id, faction_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(location, faction)
    end
  end

  @doc """
  Unlinks a quest from a location.
  """
  def unlink_quest(%Scope{} = scope, location_id, quest_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(location, quest)
    end
  end

  @doc """
  Unlinks a location from another location.
  """
  def unlink_location(%Scope{} = scope, location_id_1, location_id_2) do
    with {:ok, location_1} <- get_scoped_location(scope, location_id_1),
         {:ok, location_2} <- get_scoped_location(scope, location_id_2) do
      Links.unlink(location_1, location_2)
    end
  end

  @doc """
  Updates a link between a location and a note.
  """
  def update_link_note(%Scope{} = scope, location_id, note_id, metadata_attrs) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(location, note, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a location and a character.
  """
  def update_link_character(%Scope{} = scope, location_id, character_id, metadata_attrs) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.update_link(location, character, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a location and a faction.
  """
  def update_link_faction(%Scope{} = scope, location_id, faction_id, metadata_attrs) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.update_link(location, faction, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a location and a quest.
  """
  def update_link_quest(%Scope{} = scope, location_id, quest_id, metadata_attrs) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.update_link(location, quest, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a location and another location.
  """
  def update_link_location(%Scope{} = scope, location_id_1, location_id_2, metadata_attrs) do
    with {:ok, location_1} <- get_scoped_location(scope, location_id_1),
         {:ok, location_2} <- get_scoped_location(scope, location_id_2) do
      Links.update_link(location_1, location_2, metadata_attrs)
    end
  end

  @doc """
  Checks if a character is linked to a location.
  """
  def character_linked?(%Scope{} = scope, location_id, character_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(location, character)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a note is linked to a location.
  """
  def note_linked?(%Scope{} = scope, location_id, note_id) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(location, note)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a faction is linked to a location.
  """
  def faction_linked?(%Scope{} = scope, location_id, faction_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(location, faction)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a quest is linked to a location.
  """
  def quest_linked?(%Scope{} = scope, location_id, quest_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(location, quest)
    else
      _ -> false
    end
  end

  def location_linked?(%Scope{} = scope, location_id_1, location_id_2) do
    with {:ok, location_1} <- get_scoped_location(scope, location_id_1),
         {:ok, location_2} <- get_scoped_location(scope, location_id_2) do
      Links.linked?(location_1, location_2)
    else
      _ -> false
    end
  end

  @doc """
  Returns all characters linked to a location.
  """
  def linked_characters(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} ->
        links = Links.links_for(location)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all notes linked to a location.
  """
  def linked_notes(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} ->
        links = Links.links_for(location)
        Map.get(links, :notes, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all factions linked to a location.
  """
  def linked_factions(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} ->
        links = Links.links_for(location)
        Map.get(links, :factions, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all quests linked to a location.
  """
  def linked_quests(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} ->
        links = Links.links_for(location)
        Map.get(links, :quests, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all locations linked to a location.
  """
  def linked_locations(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} ->
        links = Links.links_for(location)
        Map.get(links, :locations, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all links for a location.
  """
  def links(%Scope{} = scope, location_id) do
    case get_scoped_location(scope, location_id) do
      {:ok, location} -> Links.links_for(location)
      {:error, _} -> %{}
    end
  end

  ## Tag-related functions

  @doc """
  Returns locations filtered by tags.

  ## Examples

      iex> list_locations_by_tags(scope, ["urban", "dangerous"])
      [%Location{}, ...]

  """
  def list_locations_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(l in Location,
      where: l.user_id == ^scope.user.id and fragment("? @> ?", l.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns locations for a game filtered by tags.

  ## Examples

      iex> list_locations_for_game_by_tags(scope, ["urban", "dangerous"])
      [%Location{}, ...]

  """
  def list_locations_for_game_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(l in Location,
      where: l.game_id == ^scope.game.id and fragment("? @> ?", l.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns all unique tags used across all locations for a user.

  ## Examples

      iex> list_all_location_tags(scope)
      ["urban", "dangerous", "peaceful", "magical"]

  """
  def list_all_location_tags(%Scope{} = scope) do
    from(l in Location,
      where: l.user_id == ^scope.user.id,
      select: l.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns all unique tags used across locations for a specific game.

  ## Examples

      iex> list_all_location_tags_for_game(scope)
      ["urban", "dangerous", "peaceful"]

  """
  def list_all_location_tags_for_game(%Scope{} = scope) do
    from(l in Location,
      where: l.game_id == ^scope.game.id,
      select: l.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  ## Pinning Management

  @doc """
  Pins a location for a specific game.
  Only users who can access the game can pin its locations.
  """
  def pin_location(%Scope{} = scope, %Location{} = location) do
    with {:ok, %Location{} = location} <-
           location
           |> Location.changeset(%{pinned: true}, scope, location.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, location})
      {:ok, location}
    end
  end

  @doc """
  Unpins a location for a specific game.
  Only users who can access the game can unpin its locations.
  """
  def unpin_location(%Scope{} = scope, %Location{} = location) do
    with {:ok, %Location{} = location} <-
           location
           |> Location.changeset(%{pinned: false}, scope, location.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, location})
      {:ok, location}
    end
  end

  @doc """
  Lists all pinned locations for a specific game.
  Only users who can access the game can see its pinned locations.
  """
  def list_pinned_locations_for_game(%Scope{} = scope) do
    from(l in Location, where: l.game_id == ^scope.game.id and l.pinned == true)
    |> Repo.all()
  end

  @doc false
  defp create_links_for_location(%Scope{} = scope, %Location{} = location, links) do
    with {:ok, target_entities_with_metadata} <-
           Links.prepare_target_entities_for_links(scope, links),
         {:ok, created_links} <-
           Links.create_multiple_links(location, target_entities_with_metadata) do
      {:ok, {created_links, location}}
    end
  end

  ## Visibility and Sharing Management

  @doc """
  Update location visibility.
  Only creator or elevated roles can change visibility.
  """
  def update_location_visibility(%Scope{} = scope, %Location{} = location, visibility) do
    with {:ok, _} <- Authorization.update_entity_visibility(scope, location, visibility),
         {:ok, location} <-
           location
           |> Ecto.Changeset.change(visibility: visibility)
           |> Repo.update() do
      broadcast(scope, {:updated, location})
      {:ok, location}
    end
  end

  @doc """
  Share a location with another user.
  Delegates to Authorization module.
  """
  defdelegate share_location(scope, location, user_id, permission),
    to: Authorization,
    as: :share_entity

  @doc """
  Remove a share for a location.
  Delegates to Authorization module.
  """
  defdelegate unshare_location(scope, location, user_id),
    to: Authorization,
    as: :unshare_entity

  @doc """
  List all shares for a location.
  Delegates to Authorization module.
  """
  defdelegate list_location_shares(scope, location),
    to: Authorization,
    as: :list_entity_shares
end
