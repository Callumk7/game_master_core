defmodule GameMasterCore.Quests do
  @moduledoc """
  The Quests context.
  """

  import Ecto.Query, warn: false
  import GameMasterCore.Helpers

  alias GameMasterCore.Repo
  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Links

  @doc """
  Subscribes to scoped notifications about any quest changes.

  The broadcasted messages match the pattern:

    * {:created, %Quest{}}
    * {:updated, %Quest{}}
    * {:deleted, %Quest{}}

  """
  def subscribe_quests(%Scope{} = scope) do
    key = scope.game.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "game:#{key}:quests")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.game.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "game:#{key}:quests", message)
  end

  @doc """
  Returns a list of quests for a specific game.
  """
  def list_quests_for_game(%Scope{} = scope) do
    from(q in Quest, where: q.game_id == ^scope.game.id)
    |> Repo.all()
  end

  @doc """
  Gets a single quest for a specific game defined in the scope.
  """
  def get_quest_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Quest, id: id, game_id: scope.game.id)
  end

  @doc """
  Create a quest for a specific game defined in the scope.
  """
  def create_quest_for_game(%Scope{} = scope, attrs) do
    with {:ok, quest = %Quest{}} <-
           %Quest{}
           |> Quest.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, quest})
      {:ok, quest}
    end
  end

  @doc """
  Returns the list of quests.

  ## Examples

      iex> list_quests(scope)
      [%Quest{}, ...]

  """
  def list_quests(%Scope{} = scope) do
    Repo.all_by(Quest, game_id: scope.game.id)
  end

  @doc """
  Gets a single quest.

  Raises `Ecto.NoResultsError` if the Quest does not exist.

  ## Examples

      iex> get_quest!(scope, 123)
      %Quest{}

      iex> get_quest!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_quest!(%Scope{} = scope, id) do
    Repo.get_by!(Quest, id: id, game_id: scope.game.id)
  end

  @doc """
  Creates a quest.

  ## Examples

      iex> create_quest(scope, %{field: value})
      {:ok, %Quest{}}

      iex> create_quest(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quest(%Scope{} = scope, attrs) do
    with {:ok, quest = %Quest{}} <-
           %Quest{}
           |> Quest.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, quest})
      {:ok, quest}
    end
  end

  @doc """
  Updates a quest.

  ## Examples

      iex> update_quest(scope, quest, %{field: new_value})
      {:ok, %Quest{}}

      iex> update_quest(scope, quest, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quest(%Scope{} = scope, %Quest{} = quest, attrs) do
    # Note: game access already validated in controller before fetching the quest
    with {:ok, quest = %Quest{}} <-
           quest
           |> Quest.changeset(attrs, scope, quest.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, quest})
      {:ok, quest}
    end
  end

  @doc """
  Deletes a quest.

  ## Examples

      iex> delete_quest(scope, quest)
      {:ok, %Quest{}}

      iex> delete_quest(scope, quest)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quest(%Scope{} = scope, %Quest{} = quest) do
    # Note: game access already validated in controller before fetching the quest
    with {:ok, quest = %Quest{}} <-
           Repo.delete(quest) do
      broadcast(scope, {:deleted, quest})
      {:ok, quest}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quest changes.

  ## Examples

      iex> change_quest(scope, quest)
      %Ecto.Changeset{data: %Quest{}}

  """
  def change_quest(%Scope{} = scope, %Quest{} = quest, attrs \\ %{}) do
    true = quest.game_id == scope.game.id

    Quest.changeset(quest, attrs, scope, scope.game.id)
  end

  # Quest Links

  @doc """
  Links a quest to a note.
  """
  def link_note(%Scope{} = scope, quest_id, note_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(quest, note)
    end
  end

  def note_linked?(%Scope{} = scope, quest_id, note_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.linked?(quest, note)
    else
      _ -> false
    end
  end

  def unlink_note(%Scope{} = scope, quest_id, note_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.unlink(quest, note)
    end
  end

  @doc """
  Links a quest to a character.
  """
  def link_character(%Scope{} = scope, quest_id, character_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.link(quest, character)
    end
  end

  def character_linked?(%Scope{} = scope, quest_id, character_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.linked?(quest, character)
    else
      _ -> false
    end
  end

  def unlink_character(%Scope{} = scope, quest_id, character_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.unlink(quest, character)
    end
  end

  @doc """
  Links a quest to a faction.
  """
  def link_faction(%Scope{} = scope, quest_id, faction_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(quest, faction)
    end
  end

  def faction_linked?(%Scope{} = scope, quest_id, faction_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.linked?(quest, faction)
    else
      _ -> false
    end
  end

  def unlink_faction(%Scope{} = scope, quest_id, faction_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.unlink(quest, faction)
    end
  end

  @doc """
  Links a quest to a location.
  """
  def link_location(%Scope{} = scope, quest_id, location_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.link(quest, location)
    end
  end

  def location_linked?(%Scope{} = scope, quest_id, location_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.linked?(quest, location)
    else
      _ -> false
    end
  end

  def unlink_location(%Scope{} = scope, quest_id, location_id) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.unlink(quest, location)
    end
  end

  @doc """
  Returns all notes linked to a quest.

  ## Examples

      iex> linked_notes(scope, quest_id)
      [%Note{}, %Note{}]

      iex> linked_notes(scope, bad_quest_id)
      []

  """
  def linked_notes(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} ->
        links = Links.links_for(quest)
        Map.get(links, :notes, [])

      {:error, _} ->
        []
    end
  end

  def linked_characters(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} ->
        links = Links.links_for(quest)
        Map.get(links, :characters, [])

      {:error, _} ->
        []
    end
  end

  def linked_factions(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} ->
        links = Links.links_for(quest)
        Map.get(links, :factions, [])

      {:error, _} ->
        []
    end
  end

  def linked_locations(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} ->
        links = Links.links_for(quest)
        Map.get(links, :locations, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Returns all links for a quest.
  """
  def links(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} -> Links.links_for(quest)
      {:error, _} -> %{}
    end
  end
end
