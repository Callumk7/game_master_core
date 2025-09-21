defmodule GameMasterCore.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  import GameMasterCore.Helpers

  alias GameMasterCore.Repo
  alias GameMasterCore.Notes.Note
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Links

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
  Returns a hierarchical tree of notes for a specific character.
  
  This includes:
  1. Direct child notes (parent_id = character_id, parent_type = "Character") 
  2. Traditional note hierarchies beneath those notes (parent_id = note_id, parent_type = nil)
  
  ## Examples

      iex> list_character_notes_tree_for_game(scope, character_id)
      [%Note{children: [%Note{}, ...]}, ...]

  """
  def list_character_notes_tree_for_game(%Scope{} = scope, character_id) do
    # Get all notes in the game
    all_notes = 
      from(n in Note, 
        where: n.game_id == ^scope.game.id,
        order_by: [asc: n.name]
      )
      |> Repo.all()

    # Filter to notes that belong to this character's tree and build hierarchy
    build_entity_note_tree(all_notes, character_id, "character")
  end

  defp build_entity_note_tree(all_notes, entity_id, entity_type) do
    # Group all notes by their parent relationship
    grouped = Enum.group_by(all_notes, fn note ->
      if note.parent_id && note.parent_type do
        # Polymorphic parent: {parent_id, parent_type}
        {note.parent_id, note.parent_type}
      else
        # Traditional note parent: {parent_id, "Note"}
        {note.parent_id, "Note"}
      end
    end)

    # Start with direct children of the entity
    root_notes = Map.get(grouped, {entity_id, entity_type}, [])
    
    # Build the tree recursively
    Enum.map(root_notes, &add_note_children(&1, grouped))
  end

  defp add_note_children(note, grouped) do
    # Find children of this note (traditional note hierarchy)
    children = Map.get(grouped, {note.id, "Note"}, [])
    
    # Recursively add children
    children_with_trees = Enum.map(children, &add_note_children(&1, grouped))
    
    # Add children to the note struct
    Map.put(note, :children, children_with_trees)
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

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(scope, note)
      {:ok, %Note{}}

      iex> delete_note(scope, note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Scope{} = scope, %Note{} = note) do
    # Note: game access already validated in controller before fetching the note
    with {:ok, note = %Note{}} <-
           Repo.delete(note) do
      broadcast(scope, {:deleted, note})
      {:ok, note}
    end
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
end
