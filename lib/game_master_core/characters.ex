defmodule GameMasterCore.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Characters.CharacterFaction
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Notes
  alias GameMasterCore.Links
  alias GameMasterCore.Factions
  alias GameMasterCore.Locations
  alias GameMasterCore.Quests

  @doc """
  Subscribes to scoped notifications about any character changes.

  The broadcasted messages match the pattern:

    * {:created, %Character{}}
    * {:updated, %Character{}}
    * {:deleted, %Character{}}

  """
  def subscribe_characters(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:characters")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:characters", message)
  end

  @doc """
  Returns this list of characters for a specific game.
  Only users who can access the game can see its characters.
  """
  def list_characters_for_game(%Scope{} = scope) do
    from(c in Character, where: c.game_id == ^scope.game.id)
    |> Repo.all()
  end

  @doc """
  Gets a single character for a specific game.
  Only users who can access the game can access its characters.

  Raises `Ecto.NoResultsError` if the Character does not exist.
  """
  def get_character_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Character, id: id, game_id: scope.game.id)
  end

  @doc """
  Fetches a single character for a specific game.
  Only users who can access the game can access its characters.

  Returns `{:ok, character}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_character_for_game(%Scope{} = scope, id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get_by(Character, id: uuid, game_id: scope.game.id) do
          nil -> {:error, :not_found}
          character -> {:ok, character}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Create a character for a specific game.
  """
  def create_character_for_game(%Scope{} = scope, attrs) do
    with {:ok, character = %Character{}} <-
           %Character{}
           |> Character.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, character})
      {:ok, character}
    end
  end

  @doc """
  Returns the list of characters.

  ## Examples

      iex> list_characters(scope)
      [%Character{}, ...]

  """
  def list_characters(%Scope{} = scope) do
    Repo.all_by(Character, user_id: scope.user.id)
  end

  @doc """
  Gets a single character.

  Raises `Ecto.NoResultsError` if the Character does not exist.

  ## Examples

      iex> get_character!(scope, 123)
      %Character{}

      iex> get_character!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_character!(%Scope{} = scope, id) do
    Repo.get_by!(Character, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a character.

  ## Examples

      iex> create_character(scope, %{field: value})
      {:ok, %Character{}}

      iex> create_character(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_character(%Scope{} = scope, attrs) do
    # This function now requires game_id in attrs
    game_id = Map.get(attrs, "game_id") || Map.get(attrs, :game_id)

    if game_id do
      with {:ok, character = %Character{}} <-
             %Character{}
             |> Character.changeset(attrs, scope, game_id)
             |> Repo.insert() do
        broadcast(scope, {:created, character})
        {:ok, character}
      end
    else
      {:error, :game_id_required}
    end
  end

  @doc """
  Updates a character.

  ## Examples

      iex> update_character(scope, character, %{field: new_value})
      {:ok, %Character{}}

      iex> update_character(scope, character, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_character(%Scope{} = scope, %Character{} = character, attrs) do
    # Note: game access already validated in controller before fetching the character
    with {:ok, character = %Character{}} <-
           character
           |> Character.changeset(attrs, scope, character.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, character})
      {:ok, character}
    end
  end

  @doc """
  Deletes a character.

  ## Examples

      iex> delete_character(scope, character)
      {:ok, %Character{}}

      iex> delete_character(scope, character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_character(%Scope{} = scope, %Character{} = character) do
    # Note: game access already validated in controller before fetching the character
    with {:ok, character = %Character{}} <-
           Repo.delete(character) do
      broadcast(scope, {:deleted, character})
      {:ok, character}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking character changes.

  ## Examples

      iex> change_character(scope, character)
      %Ecto.Changeset{data: %Character{}}

  """
  def change_character(%Scope{} = scope, %Character{} = character, attrs \\ %{}) do
    Character.changeset(character, attrs, scope, character.game_id)
  end

  ## Character Links

  @doc """
  Links a character to a note.

  ## Examples

      iex> link_note(scope, character_id, note_id)
      {:ok, %CharacterNote{}}

      iex> link_note(scope, bad_character_id, note_id)
      {:error, :character_not_found}

  """
  def link_note(%Scope{} = scope, character_id, note_id, metadata_attrs \\ %{}) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(character, note, metadata_attrs)
    end
  end

  @doc """
  Links a faction to a character.
  """
  def link_faction(%Scope{} = scope, character_id, faction_id, metadata_attrs \\ %{}) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(character, faction, metadata_attrs)
    end
  end

  @doc """
  Links a quest to a character.
  """
  def link_quest(%Scope{} = scope, character_id, quest_id, metadata_attrs \\ %{}) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.link(character, quest, metadata_attrs)
    end
  end

  @doc """
  Links a location to a character.
  """
  def link_location(%Scope{} = scope, character_id, location_id, metadata_attrs \\ %{}) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.link(character, location, metadata_attrs)
    end
  end

  @doc """
  Links a character to another character.
  """
  def link_character(%Scope{} = scope, character_id_1, character_id_2, metadata_attrs \\ %{}) do
    with {:ok, character_1} <- get_scoped_character(scope, character_id_1),
         {:ok, character_2} <- get_scoped_character(scope, character_id_2) do
      Links.link(character_1, character_2, metadata_attrs)
    end
  end

  @doc """
  Unlinks a character from a note.

  ## Examples

      iex> unlink_note(scope, character_id, note_id)
      {:ok, %CharacterNote{}}

      iex> unlink_note(scope, character_id, note_id)
      {:error, :not_found}

  """
  def unlink_note(%Scope{} = scope, character_id, note_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(character, note)
    end
  end

  @doc """
  Unlinks a character from a faction.
  """
  def unlink_faction(%Scope{} = scope, character_id, faction_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.unlink(character, faction)
    end
  end

  @doc """
  Unlinks a character from a quest.
  """
  def unlink_quest(%Scope{} = scope, character_id, quest_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.unlink(character, quest)
    end
  end

  @doc """
  Unlinks a character from a location.
  """
  def unlink_location(%Scope{} = scope, character_id, location_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(character, location)
    end
  end

  @doc """
  Unlinks a character from another character.
  """
  def unlink_character(%Scope{} = scope, character_id_1, character_id_2) do
    with {:ok, character_1} <- get_scoped_character(scope, character_id_1),
         {:ok, character_2} <- get_scoped_character(scope, character_id_2) do
      Links.unlink(character_1, character_2)
    end
  end

  @doc """
  Updates a link between a character and a note.
  """
  def update_link_note(%Scope{} = scope, character_id, note_id, metadata_attrs) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(character, note, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a character and a faction.
  """
  def update_link_faction(%Scope{} = scope, character_id, faction_id, metadata_attrs) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.update_link(character, faction, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a character and a location.
  """
  def update_link_location(%Scope{} = scope, character_id, location_id, metadata_attrs) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.update_link(character, location, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a character and a quest.
  """
  def update_link_quest(%Scope{} = scope, character_id, quest_id, metadata_attrs) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.update_link(character, quest, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a character and another character.
  """
  def update_link_character(%Scope{} = scope, character_id_1, character_id_2, metadata_attrs) do
    with {:ok, character_1} <- get_scoped_character(scope, character_id_1),
         {:ok, character_2} <- get_scoped_character(scope, character_id_2) do
      Links.update_link(character_1, character_2, metadata_attrs)
    end
  end

  @doc """
  Checks if a character is linked to a note.

  ## Examples

      iex> note_linked?(scope, character_id, note_id)
      true

      iex> note_linked?(scope, character_id, note_id)
      false

  """
  def note_linked?(%Scope{} = scope, character_id, note_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(character, note)
    else
      _ -> false
    end
  end

  def faction_linked?(%Scope{} = scope, character_id, faction_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.linked?(character, faction)
    else
      _ -> false
    end
  end

  def quest_linked?(%Scope{} = scope, character_id, quest_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.linked?(character, quest)
    else
      _ -> false
    end
  end

  def location_linked?(%Scope{} = scope, character_id, location_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(character, location)
    else
      _ -> false
    end
  end

  def character_linked?(%Scope{} = scope, character_id_1, character_id_2) do
    with {:ok, character_1} <- get_scoped_character(scope, character_id_1),
         {:ok, character_2} <- get_scoped_character(scope, character_id_2) do
      Links.linked?(character_1, character_2)
    else
      _ -> false
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
  def linked_notes(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} ->
        links = Links.links_for(character)
        Map.get(links, :notes, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all factions linked to a character.
  """
  def linked_factions(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} ->
        links = Links.links_for(character)
        Map.get(links, :factions, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all quests linked to a character.
  """
  def linked_quests(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} ->
        links = Links.links_for(character)
        Map.get(links, :quests, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all locations linked to a character.
  """
  def linked_locations(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} ->
        links = Links.links_for(character)
        Map.get(links, :locations, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all characters linked to a character.
  """
  def linked_characters(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} ->
        links = Links.links_for(character)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end

  def links(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} -> Links.links_for(character)
      {:error, _} -> %{}
    end
  end

  ## Tag-related functions

  @doc """
  Returns characters filtered by tags.

  ## Examples

      iex> list_characters_by_tags(scope, ["npc", "villain"])
      [%Character{}, ...]

  """
  def list_characters_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(c in Character,
      where: c.user_id == ^scope.user.id and fragment("? @> ?", c.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns characters for a game filtered by tags.

  ## Examples

      iex> list_characters_for_game_by_tags(scope, ["npc", "villain"])
      [%Character{}, ...]

  """
  def list_characters_for_game_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(c in Character,
      where: c.game_id == ^scope.game.id and fragment("? @> ?", c.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns all unique tags used across all characters for a user.

  ## Examples

      iex> list_all_character_tags(scope)
      ["npc", "villain", "ally", "merchant"]

  """
  def list_all_character_tags(%Scope{} = scope) do
    from(c in Character,
      where: c.user_id == ^scope.user.id,
      select: c.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns all unique tags used across characters for a specific game.

  ## Examples

      iex> list_all_character_tags_for_game(scope)
      ["npc", "villain", "ally"]

  """
  def list_all_character_tags_for_game(%Scope{} = scope) do
    from(c in Character,
      where: c.game_id == ^scope.game.id,
      select: c.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Private helper functions for character links

  defp get_scoped_character(scope, character_id) do
    try do
      character = get_character_for_game!(scope, character_id)
      {:ok, character}
    rescue
      Ecto.NoResultsError -> {:error, :character_not_found}
    end
  end

  defp get_scoped_note(scope, note_id) do
    try do
      note = Notes.get_note_for_game!(scope, note_id)
      {:ok, note}
    rescue
      Ecto.NoResultsError -> {:error, :note_not_found}
    end
  end

  defp get_scoped_faction(scope, faction_id) do
    try do
      faction = Factions.get_faction_for_game!(scope, faction_id)
      {:ok, faction}
    rescue
      Ecto.NoResultsError -> {:error, :faction_not_found}
    end
  end

  defp get_scoped_quest(scope, quest_id) do
    try do
      quest = Quests.get_quest_for_game!(scope, quest_id)
      {:ok, quest}
    rescue
      Ecto.NoResultsError -> {:error, :quest_not_found}
    end
  end

  defp get_scoped_location(scope, location_id) do
    try do
      location = Locations.get_location_for_game!(scope, location_id)
      {:ok, location}
    rescue
      Ecto.NoResultsError -> {:error, :location_not_found}
    end
  end

  ## Pinning Management

  @doc """
  Pins a character for a specific game.
  Only users who can access the game can pin its characters.
  """
  def pin_character(%Scope{} = scope, %Character{} = character) do
    with {:ok, %Character{} = character} <-
           character
           |> Character.changeset(%{pinned: true}, scope, character.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, character})
      {:ok, character}
    end
  end

  @doc """
  Unpins a character for a specific game.
  Only users who can access the game can unpin its characters.
  """
  def unpin_character(%Scope{} = scope, %Character{} = character) do
    with {:ok, %Character{} = character} <-
           character
           |> Character.changeset(%{pinned: false}, scope, character.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, character})
      {:ok, character}
    end
  end

  @doc """
  Lists all pinned characters for a specific game.
  Only users who can access the game can see its pinned characters.
  """
  def list_pinned_characters_for_game(%Scope{} = scope) do
    from(c in Character, where: c.game_id == ^scope.game.id and c.pinned == true)
    |> Repo.all()
  end

  ## Primary Faction Management

  @doc """
  Gets the primary faction for a character, including faction details.
  Returns {:ok, primary_faction_data} or {:error, :no_primary_faction}
  """
  def get_primary_faction(%Scope{} = scope, %Character{} = character) do
    if character.member_of_faction_id do
      case Factions.fetch_faction_for_game(scope, character.member_of_faction_id) do
        {:ok, faction} ->
          {:ok,
           %{
             faction: faction,
             role: character.faction_role,
             character_id: character.id
           }}

        {:error, :not_found} ->
          {:error, :no_primary_faction}
      end
    else
      {:error, :no_primary_faction}
    end
  end

  @doc """
  Sets a character's primary faction and creates/updates the corresponding
  CharacterFaction relationship record for consistency.
  """
  def set_primary_faction(%Scope{} = scope, %Character{} = character, faction_id, role) do
    Repo.transaction(fn ->
      # First validate that the faction exists in the same game
      case Factions.fetch_faction_for_game(scope, faction_id) do
        {:error, :not_found} ->
          Repo.rollback({:error, :faction_not_found})

        {:ok, _faction} ->
          # Update the character's primary faction fields
          changeset =
            Character.changeset(
              character,
              %{
                member_of_faction_id: faction_id,
                faction_role: role
              },
              scope,
              character.game_id
            )

          case Repo.update(changeset) do
            {:ok, updated_character} ->
              # Create or update the CharacterFaction relationship record
              create_or_update_character_faction_link(character.id, faction_id, role)

              broadcast(scope, {:updated, updated_character})
              updated_character

            {:error, changeset} ->
              Repo.rollback({:error, changeset})
          end
      end
    end)
  end

  @doc """
  Removes a character's primary faction while preserving the CharacterFaction
  relationship record (as per the original plan).
  """
  def remove_primary_faction(%Scope{} = scope, %Character{} = character) do
    changeset =
      Character.changeset(
        character,
        %{
          member_of_faction_id: nil,
          faction_role: nil
        },
        scope,
        character.game_id
      )

    case Repo.update(changeset) do
      {:ok, updated_character} ->
        # Note: We preserve the CharacterFaction record as designed
        # This maintains the relationship history even when primary status is removed
        broadcast(scope, {:updated, updated_character})
        {:ok, updated_character}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Private helper to create or update CharacterFaction link
  defp create_or_update_character_faction_link(character_id, faction_id, role) do
    # Check if a CharacterFaction record already exists
    existing =
      from(cf in CharacterFaction,
        where: cf.character_id == ^character_id and cf.faction_id == ^faction_id
      )
      |> Repo.one()

    case existing do
      nil ->
        # Create new CharacterFaction record
        %CharacterFaction{}
        |> CharacterFaction.changeset(%{
          character_id: character_id,
          faction_id: faction_id,
          # Use the role as relationship_type for consistency
          relationship_type: role,
          is_active: true
        })
        |> Repo.insert()

      existing_record ->
        # Update existing record to ensure it's active and has current role info
        existing_record
        |> CharacterFaction.changeset(%{
          relationship_type: role,
          is_active: true
        })
        |> Repo.update()
    end
  end
end
