defmodule GameMasterCore.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  import GameMasterCore.Helpers

  alias GameMasterCore.Accounts.User
  alias GameMasterCore.Repo
  alias GameMasterCore.Notes.Note
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Images
  alias GameMasterCore.Links

  @behaviour Bodyguard.Policy

  @doc """
  Subscribes to scoped notifications about any note changes.

  The broadcasted messages match the pattern:

    * {:created, %Note{}}
    * {:updated, %Note{}}
    * {:deleted, %Note{}}

  """
  def subscribe_notes(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:notes")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:notes", message)
  end

  @doc """
  Returns the list of notes for a specific game.
  Only users who can access the game can see its notes.

  ## Examples

      iex> list_notes_for_game(scope, game)
      [%Note{}, ...]

  """
  def list_notes_for_game(%Scope{} = scope) do
    # Games.get_game! already validates access, so if we got the game, we can access its notes
    from(n in Note, where: n.game_id == ^scope.game.id)
    |> Repo.all()
  end

  @doc """
  Gets a single note for a specific game.
  Only users who can access the game can access its notes.

  Raises `Ecto.NoResultsError` if the Note does not exist.
  """
  def get_note_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Note, id: id, game_id: scope.game.id)
  end

  @doc """
  Fetches a single note for a specific game.
  Only users who can access the game can access its notes.

  Returns `{:ok, note}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_note_for_game(%Scope{} = scope, id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get_by(Note, id: uuid, game_id: scope.game.id) do
          nil -> {:error, :not_found}
          note -> {:ok, note}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a note for a specific game.

  ## Examples

      iex> create_note_for_game(scope, game, %{field: value})
      {:ok, %Note{}}

      iex> create_note_for_game(scope, game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note_for_game(%Scope{} = scope, attrs) do
    with {:ok, note = %Note{}} <-
           %Note{}
           |> Note.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, note})
      {:ok, note}
    end
  end

  @doc """
  Creates a note and establishes links to other entities in a single transaction.

  Creates the note and establishes all specified relationships in a single transaction.
  Links are expected to be a list of maps with keys:
  - entity_type: "faction", "location", "note", "quest", or "character"
  - entity_id: UUID of the entity to link to
  - Additional metadata fields like is_primary, parent_note, polymorphic_type, etc.

  ## Examples

      iex> create_note_with_links(scope, %{title: "Session Notes"}, [
        %{entity_type: "character", entity_id: character_id, note_type: "biography"}
      ])
      {:ok, %Note{}}
      
      iex> create_note_with_links(scope, %{invalid: "data"}, [])
      {:error, %Ecto.Changeset{}}
  """
  def create_note_with_links(%Scope{} = scope, attrs, links) when is_list(links) do
    Repo.transaction(fn ->
      with {:ok, note} <- create_note_for_game(scope, attrs),
           {:ok, {_links, updated_note}} <-
             create_links_for_note(scope, note, links) do
        updated_note
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(scope, note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(scope, note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Scope{} = scope, %Note{} = note, attrs) do
    # Note: game access already validated in controller before fetching the note
    with {:ok, note = %Note{}} <-
           note
           |> Note.changeset(attrs, scope, note.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, note})
      {:ok, note}
    end
  end

  # authorize update if the user is the note's owner
  def authorize(:update_note, %User{id: user_id} = _user, %Note{user_id: user_id} = _note),
    do: :ok

  # In all other cases, deny
  def authorize(:update_note, _scope, _note), do: :error

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(scope, note)
      {:ok, %Note{}}

      iex> delete_note(scope, note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Scope{} = scope, %Note{} = note) do
    Repo.transaction(fn ->
      # First, delete all associated images
      case Images.delete_images_for_entity(scope, "note", note.id) do
        {:ok, _count} ->
          # Then delete the note
          case Repo.delete(note) do
            {:ok, note} ->
              broadcast(scope, {:deleted, note})
              note

            {:error, reason} ->
              Repo.rollback(reason)
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(scope, note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Scope{} = scope, %Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs, scope, note.game_id)
  end

  # Legacy functions - kept for backward compatibility but deprecated

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes(scope)
      [%Note{}, ...]

  """
  def list_notes(%Scope{} = scope) do
    Repo.all_by(Note, user_id: scope.user.id)
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(scope, 123)
      %Note{}

      iex> get_note!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(%Scope{} = scope, id) do
    Repo.get_by!(Note, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(scope, %{field: value})
      {:ok, %Note{}}

      iex> create_note(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(%Scope{} = scope, attrs) do
    # This function now requires game_id in attrs
    game_id = Map.get(attrs, "game_id") || Map.get(attrs, :game_id)

    if game_id do
      with {:ok, note = %Note{}} <-
             %Note{}
             |> Note.changeset(attrs, scope, game_id)
             |> Repo.insert() do
        broadcast(scope, {:created, note})
        {:ok, note}
      end
    else
      {:error, :game_id_required}
    end
  end

  ## Note Links

  @doc """
  Links a character to a note.
  """
  def link_character(%Scope{} = scope, note_id, character_id, metadata_attrs \\ %{}) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.link(note, character, metadata_attrs)
    end
  end

  @doc """
  Links a faction to a note.
  """
  def link_faction(%Scope{} = scope, note_id, faction_id, metadata_attrs \\ %{}) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(note, faction, metadata_attrs)
    end
  end

  @doc """
  Links a location to a note.
  """
  def link_location(%Scope{} = scope, note_id, location_id, metadata_attrs \\ %{}) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.link(note, location, metadata_attrs)
    end
  end

  @doc """
  Links a quest to a note.
  """
  def link_quest(%Scope{} = scope, note_id, quest_id, metadata_attrs \\ %{}) do
    with {:ok, note} <- get_scoped_note(scope, note_id),
         {:ok, quest} <- get_scoped_quest(scope, quest_id) do
      Links.link(note, quest, metadata_attrs)
    end
  end

  @doc """
  Links a note to another note.
  """
  def link_note(%Scope{} = scope, note_id_1, note_id_2, metadata_attrs \\ %{}) do
    with {:ok, note_1} <- get_scoped_note(scope, note_id_1),
         {:ok, note_2} <- get_scoped_note(scope, note_id_2) do
      Links.link(note_1, note_2, metadata_attrs)
    end
  end

  @doc """
  Unlinks a character from a note.
  """
  def unlink_character(%Scope{} = scope, note_id, character_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(note, character)
    end
  end

  @doc """
  Unlinks a faction from a note.
  """
  def unlink_faction(%Scope{} = scope, note_id, faction_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(note, faction)
    end
  end

  @doc """
  Unlinks a quest from a note.
  """
  def unlink_quest(%Scope{} = scope, note_id, quest_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(note, quest)
    end
  end

  @doc """
  Unlinks a location from a note.
  """
  def unlink_location(%Scope{} = scope, note_id, location_id) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(note, location)
    end
  end

  @doc """
  Unlinks a note from another note.
  """
  def unlink_note(%Scope{} = scope, note_id_1, note_id_2) do
    with {:ok, note_1} <- get_scoped_note(scope, note_id_1),
         {:ok, note_2} <- get_scoped_note(scope, note_id_2) do
      Links.unlink(note_1, note_2)
    end
  end

  @doc """
  Updates a link between a character and a note.
  """
  def update_link_character(%Scope{} = scope, note_id, character_id, metadata_attrs) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(note, character, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a faction and a note.
  """
  def update_link_faction(%Scope{} = scope, note_id, faction_id, metadata_attrs) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(note, faction, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a quest and a note.
  """
  def update_link_quest(%Scope{} = scope, note_id, quest_id, metadata_attrs) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(note, quest, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a location and a note.
  """
  def update_link_location(%Scope{} = scope, note_id, location_id, metadata_attrs) do
    with {:ok, location} <- get_scoped_location(scope, location_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(note, location, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a note and another note.
  """
  def update_link_note(%Scope{} = scope, note_id_1, note_id_2, metadata_attrs) do
    with {:ok, note_1} <- get_scoped_note(scope, note_id_1),
         {:ok, note_2} <- get_scoped_note(scope, note_id_2) do
      Links.update_link(note_1, note_2, metadata_attrs)
    end
  end

  @doc """
  Checks if a character is linked to a note.
  """
  def character_linked?(%Scope{} = scope, note_id, character_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(note, character)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a faction is linked to a note.
  """
  def faction_linked?(%Scope{} = scope, note_id, faction_id) do
    with {:ok, faction} <- get_scoped_faction(scope, faction_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(note, faction)
    else
      _ -> false
    end
  end

  @doc """
  Checks if a quest is linked to a note.
  """
  def quest_linked?(%Scope{} = scope, note_id, quest_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(note, quest)
    else
      _ -> false
    end
  end

  def note_linked?(%Scope{} = scope, note_id_1, note_id_2) do
    with {:ok, note_1} <- get_scoped_note(scope, note_id_1),
         {:ok, note_2} <- get_scoped_note(scope, note_id_2) do
      Links.linked?(note_1, note_2)
    else
      _ -> false
    end
  end

  @doc """
  Returns all characters linked to a note.
  """
  def linked_characters(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all factions linked to a note.
  """
  def linked_factions(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :factions, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all quests linked to a note.
  """
  def linked_quests(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :quests, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all locations linked to a note.
  """
  def linked_locations(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :locations, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all notes linked to a note.
  """
  def linked_notes(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} ->
        links = Links.links_for(note)
        Map.get(links, :notes, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all links for a note.
  """
  def links(%Scope{} = scope, note_id) do
    case get_scoped_note(scope, note_id) do
      {:ok, note} -> Links.links_for(note)
      {:error, _} -> %{}
    end
  end

  ## Tag-related functions

  @doc """
  Returns notes filtered by tags.

  ## Examples

      iex> list_notes_by_tags(scope, ["important", "secret"])
      [%Note{}, ...]

  """
  def list_notes_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(n in Note,
      where: n.user_id == ^scope.user.id and fragment("? @> ?", n.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns notes for a game filtered by tags.

  ## Examples

      iex> list_notes_for_game_by_tags(scope, ["important", "secret"])
      [%Note{}, ...]

  """
  def list_notes_for_game_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(n in Note,
      where: n.game_id == ^scope.game.id and fragment("? @> ?", n.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns all unique tags used across all notes for a user.

  ## Examples

      iex> list_all_note_tags(scope)
      ["important", "secret", "lore", "reminder"]

  """
  def list_all_note_tags(%Scope{} = scope) do
    from(n in Note,
      where: n.user_id == ^scope.user.id,
      select: n.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns all unique tags used across notes for a specific game.

  ## Examples

      iex> list_all_note_tags_for_game(scope)
      ["important", "secret", "lore"]

  """
  def list_all_note_tags_for_game(%Scope{} = scope) do
    from(n in Note,
      where: n.game_id == ^scope.game.id,
      select: n.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  ## Pinning Management

  @doc """
  Pins a note for a specific game.
  Only users who can access the game can pin its notes.
  """
  def pin_note(%Scope{} = scope, %Note{} = note) do
    with {:ok, %Note{} = note} <-
           note
           |> Note.changeset(%{pinned: true}, scope, note.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, note})
      {:ok, note}
    end
  end

  @doc """
  Unpins a note for a specific game.
  Only users who can access the game can unpin its notes.
  """
  def unpin_note(%Scope{} = scope, %Note{} = note) do
    with {:ok, %Note{} = note} <-
           note
           |> Note.changeset(%{pinned: false}, scope, note.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, note})
      {:ok, note}
    end
  end

  @doc """
  Lists all pinned notes for a specific game.
  Only users who can access the game can see its pinned notes.
  """
  def list_pinned_notes_for_game(%Scope{} = scope) do
    from(n in Note, where: n.game_id == ^scope.game.id and n.pinned == true)
    |> Repo.all()
  end

  @doc false
  defp create_links_for_note(%Scope{} = scope, %Note{} = note, links) do
    with {:ok, target_entities_with_metadata} <-
           Links.prepare_target_entities_for_links(scope, links),
         {:ok, created_links} <-
           Links.create_multiple_links(note, target_entities_with_metadata) do
      {:ok, {created_links, note}}
    end
  end
end
