defmodule GameMasterCore.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Notes
  alias GameMasterCore.Links
  alias GameMasterCore.Factions

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
    true = character.user_id == scope.user.id

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
  def link_note(%Scope{} = scope, character_id, note_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(character, note)
    end
  end

  @doc """
  Links a faction to a note.
  """
  def link_faction(%Scope{} = scope, character_id, faction_id) do
    with {:ok, character} <- get_scoped_character(scope, character_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(character, faction)
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

  def links(%Scope{} = scope, character_id) do
    case get_scoped_character(scope, character_id) do
      {:ok, character} -> Links.links_for(character)
      {:error, _} -> %{}
    end
  end

  # Private helper functions for character links

  defp get_scoped_character(scope, character_id) do
    try do
      character = get_character!(scope, character_id)
      {:ok, character}
    rescue
      Ecto.NoResultsError -> {:error, :character_not_found}
    end
  end

  defp get_scoped_note(scope, note_id) do
    try do
      note = Notes.get_note!(scope, note_id)
      {:ok, note}
    rescue
      Ecto.NoResultsError -> {:error, :note_not_found}
    end
  end

  defp get_scoped_faction(scope, faction_id) do
    try do
      faction = Factions.get_faction!(scope, faction_id)
      {:ok, faction}
    rescue
      Ecto.NoResultsError -> {:error, :faction_not_found}
    end
  end
end
