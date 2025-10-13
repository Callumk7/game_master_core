defmodule GameMasterCore.Factions do
  @moduledoc """
  The Factions context.
  """

  import Ecto.Query, warn: false
  import GameMasterCore.Helpers

  alias GameMasterCore.Repo

  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Characters.CharacterFaction
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Links

  @doc """
  Subscribes to scoped notifications about any faction changes.

  The broadcasted messages match the pattern:

    * {:created, %Faction{}}
    * {:updated, %Faction{}}
    * {:deleted, %Faction{}}

  """
  def subscribe_factions(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:factions")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:factions", message)
  end

  @doc """
  Returns the list of factions for a game.
  Only users who can access the game can see its factions.
  """
  def list_factions_for_game(%Scope{} = scope) do
    from(f in Faction, where: f.game_id == ^scope.game.id)
    |> Repo.all()
  end

  @doc """
  Get a single faction for a specific game.
  Only users who can access the game can access its factions.

  Raises `Ecto.NoResultsError` if the Faction does not exist.

  ## Examples

      iex> get_faction_for_game!(scope, 123)
      %Faction{}

      iex> get_faction_for_game!(scope, 456)
      ** (Ecto.NoResultsError)
  """
  def get_faction_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Faction, id: id, game_id: scope.game.id)
  end

  @doc """
  Fetches a single faction for a specific game.
  Only users who can access the game can access its factions.

  Returns `{:ok, faction}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_faction_for_game(%Scope{} = scope, id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get_by(Faction, id: uuid, game_id: scope.game.id) do
          nil -> {:error, :not_found}
          faction -> {:ok, faction}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a faction for a specific game.
  """
  def create_faction_for_game(%Scope{} = scope, attrs) do
    with {:ok, faction = %Faction{}} <-
           %Faction{}
           |> Faction.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, faction})
      {:ok, faction}
    end
  end

  @doc """
  Returns the list of factions for a user.

  ## Examples

      iex> list_factions(scope)
      [%Faction{}, ...]

  """
  def list_factions(%Scope{} = scope) do
    Repo.all_by(Faction, user_id: scope.user.id)
  end

  @doc """
  Gets a single faction by user scope.

  Raises `Ecto.NoResultsError` if the Faction does not exist.

  ## Examples

      iex> get_faction!(scope, 123)
      %Faction{}

      iex> get_faction!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_faction!(%Scope{} = scope, id) do
    Repo.get_by!(Faction, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a faction.

  ## Examples

      iex> create_faction(scope, %{field: value})
      {:ok, %Faction{}}

      iex> create_faction(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_faction(%Scope{} = scope, attrs) do
    # This function now requires game_id in attrs
    game_id = Map.get(attrs, "game_id") || Map.get(attrs, :game_id)

    if game_id do
      with {:ok, faction = %Faction{}} <-
             %Faction{}
             |> Faction.changeset(attrs, scope, game_id)
             |> Repo.insert() do
        broadcast(scope, {:created, faction})
        {:ok, faction}
      end
    else
      {:error, :game_id_required}
    end
  end

  @doc """
  Updates a faction.

  ## Examples

      iex> update_faction(scope, faction, %{field: new_value})
      {:ok, %Faction{}}

      iex> update_faction(scope, faction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_faction(%Scope{} = scope, %Faction{} = faction, attrs) do
    # Note: game access already validated in controller before fetching the faction
    with {:ok, faction = %Faction{}} <-
           faction
           |> Faction.changeset(attrs, scope, faction.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, faction})
      {:ok, faction}
    end
  end

  @doc """
  Deletes a faction.

  ## Examples

      iex> delete_faction(scope, faction)
      {:ok, %Faction{}}

      iex> delete_faction(scope, faction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_faction(%Scope{} = scope, %Faction{} = faction) do
    # Note: game access already validated in controller before fetching the faction
    with {:ok, faction = %Faction{}} <-
           Repo.delete(faction) do
      broadcast(scope, {:deleted, faction})
      {:ok, faction}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking faction changes.

  ## Examples

      iex> change_faction(scope, faction)
      %Ecto.Changeset{data: %Faction{}}

  """
  def change_faction(%Scope{} = scope, %Faction{} = faction, attrs \\ %{}) do
    Faction.changeset(faction, attrs, scope, faction.game_id)
  end

  @doc """
  Links a faction to a note.
  """
  def link_note(%Scope{} = scope, faction_id, note_id, metadata_attrs \\ %{}) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(faction, note, metadata_attrs)
    end
  end

  def note_linked?(%Scope{} = scope, faction_id, note_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(faction, note)
    else
      _ -> false
    end
  end

  def unlink_note(%Scope{} = scope, faction_id, note_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(faction, note)
    end
  end

  @doc """
  Links a faction to a character.
  """
  def link_character(%Scope{} = scope, faction_id, character_id, metadata_attrs \\ %{}) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.link(faction, character, metadata_attrs)
    end
  end

  def link_location(%Scope{} = scope, faction_id, location_id, metadata_attrs \\ %{}) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.link(faction, location, metadata_attrs)
    end
  end

  @doc """
  Links a faction to a quest.
  """
  def link_quest(%Scope{} = scope, faction_id, quest_id, metadata_attrs \\ %{}) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.link(faction, quest, metadata_attrs)
    end
  end

  @doc """
  Links a faction to another faction.
  """
  def link_faction(%Scope{} = scope, faction_id_1, faction_id_2, metadata_attrs \\ %{}) do
    with {:ok, faction_1} <- get_scoped_faction(scope, faction_id_1),
         {:ok, faction_2} <- get_scoped_faction(scope, faction_id_2) do
      Links.link(faction_1, faction_2, metadata_attrs)
    end
  end

  def character_linked?(%Scope{} = scope, faction_id, character_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.linked?(faction, character)
    else
      _ -> false
    end
  end

  def quest_linked?(%Scope{} = scope, faction_id, quest_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.linked?(faction, quest)
    else
      _ -> false
    end
  end

  def location_linked?(%Scope{} = scope, faction_id, location_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(faction, location)
    else
      _ -> false
    end
  end

  def faction_linked?(%Scope{} = scope, faction_id_1, faction_id_2) do
    with {:ok, faction_1} <- get_scoped_faction(scope, faction_id_1),
         {:ok, faction_2} <- get_scoped_faction(scope, faction_id_2) do
      Links.linked?(faction_1, faction_2)
    else
      _ -> false
    end
  end

  def unlink_character(%Scope{} = scope, faction_id, character_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.unlink(faction, character)
    end
  end

  def unlink_quest(%Scope{} = scope, faction_id, quest_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.unlink(faction, quest)
    end
  end

  def unlink_location(%Scope{} = scope, faction_id, location_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(faction, location)
    end
  end

  @doc """
  Unlinks a faction from another faction.
  """
  def unlink_faction(%Scope{} = scope, faction_id_1, faction_id_2) do
    with {:ok, faction_1} <- get_scoped_faction(scope, faction_id_1),
         {:ok, faction_2} <- get_scoped_faction(scope, faction_id_2) do
      Links.unlink(faction_1, faction_2)
    end
  end

  @doc """
  Updates a link between a faction and a note.
  """
  def update_link_note(%Scope{} = scope, faction_id, note_id, metadata_attrs) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(faction, note, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a faction and a character.
  """
  def update_link_character(%Scope{} = scope, faction_id, character_id, metadata_attrs) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.update_link(faction, character, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a faction and a location.
  """
  def update_link_location(%Scope{} = scope, faction_id, location_id, metadata_attrs) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.update_link(faction, location, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a faction and a quest.
  """
  def update_link_quest(%Scope{} = scope, faction_id, quest_id, metadata_attrs) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.update_link(faction, quest, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a faction and another faction.
  """
  def update_link_faction(%Scope{} = scope, faction_id_1, faction_id_2, metadata_attrs) do
    with {:ok, faction_1} <- get_scoped_faction(scope, faction_id_1),
         {:ok, faction_2} <- get_scoped_faction(scope, faction_id_2) do
      Links.update_link(faction_1, faction_2, metadata_attrs)
    end
  end

  @doc """
  Returns all notes linked to a character.

  ## Examples

      iex> linked_notes(scope, character_id)
      [%Note{}, %Note{}]

      iex> linked_notes(scope, bad_character_id)
      []

  """
  def linked_notes(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} ->
        links = Links.links_for(faction)
        Map.get(links, :notes, [])

      {:error, _} ->
        []
    end
  end

  def linked_characters(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} ->
        links = Links.links_for(faction)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end

  def linked_quests(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} ->
        links = Links.links_for(faction)
        Map.get(links, :quests, [])

      {:error, _} ->
        []
    end
  end

  def linked_locations(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} ->
        links = Links.links_for(faction)
        Map.get(links, :locations, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all factions linked to a faction.
  """
  def linked_factions(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} ->
        links = Links.links_for(faction)
        Map.get(links, :factions, [])

      {:error, _} ->
        []
    end
  end

  ## Tag-related functions

  @doc """
  Returns factions filtered by tags.

  ## Examples

      iex> list_factions_by_tags(scope, ["political", "merchant"])
      [%Faction{}, ...]

  """
  def list_factions_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(f in Faction,
      where: f.user_id == ^scope.user.id and fragment("? @> ?", f.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns factions for a game filtered by tags.

  ## Examples

      iex> list_factions_for_game_by_tags(scope, ["political", "merchant"])
      [%Faction{}, ...]

  """
  def list_factions_for_game_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(f in Faction,
      where: f.game_id == ^scope.game.id and fragment("? @> ?", f.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns all characters that are members of a specific faction.

  This queries characters where member_of_faction_id matches the given faction_id.

  ## Examples

      iex> list_faction_members(scope, faction_id)
      [%Character{}, %Character{}]

      iex> list_faction_members(scope, non_existent_faction_id)
      []

  """
  def list_faction_members(%Scope{} = scope, faction_id) do
    # First verify the faction exists and is accessible in this game
    case fetch_faction_for_game(scope, faction_id) do
      {:ok, _faction} ->
        from(c in Character,
          join: cf in CharacterFaction,
          on: cf.character_id == c.id,
          where: c.game_id == ^scope.game.id and cf.faction_id == ^faction_id and cf.is_primary == true
        )
        |> Repo.all()

      {:error, :not_found} ->
        []
    end
  end

  @doc """
  Returns all links for a faction.
  """
  def links(%Scope{} = scope, faction_id) do
    case get_scoped_faction(scope, faction_id) do
      {:ok, faction} -> Links.links_for(faction)
      {:error, _} -> %{}
    end
  end

  @doc """
  Returns all unique tags used across all factions for a user.

  ## Examples

      iex> list_all_faction_tags(scope)
      ["political", "merchant", "criminal", "religious"]

  """
  def list_all_faction_tags(%Scope{} = scope) do
    from(f in Faction,
      where: f.user_id == ^scope.user.id,
      select: f.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns all unique tags used across factions for a specific game.

  ## Examples

      iex> list_all_faction_tags_for_game(scope)
      ["political", "merchant", "criminal"]

  """
  def list_all_faction_tags_for_game(%Scope{} = scope) do
    from(f in Faction,
      where: f.game_id == ^scope.game.id,
      select: f.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  ## Pinning Management

  @doc """
  Pins a faction for a specific game.
  Only users who can access the game can pin its factions.
  """
  def pin_faction(%Scope{} = scope, %Faction{} = faction) do
    with {:ok, %Faction{} = faction} <-
           faction
           |> Faction.changeset(%{pinned: true}, scope, faction.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, faction})
      {:ok, faction}
    end
  end

  @doc """
  Unpins a faction for a specific game.
  Only users who can access the game can unpin its factions.
  """
  def unpin_faction(%Scope{} = scope, %Faction{} = faction) do
    with {:ok, %Faction{} = faction} <-
           faction
           |> Faction.changeset(%{pinned: false}, scope, faction.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, faction})
      {:ok, faction}
    end
  end

  @doc """
  Lists all pinned factions for a specific game.
  Only users who can access the game can see its pinned factions.
  """
  def list_pinned_factions_for_game(%Scope{} = scope) do
    from(f in Faction, where: f.game_id == ^scope.game.id and f.pinned == true)
    |> Repo.all()
  end
end
