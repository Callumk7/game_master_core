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
  Fetches a single quest for a specific game.
  Only users who can access the game can access its quests.

  Returns `{:ok, quest}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_quest_for_game(%Scope{} = scope, id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        case Repo.get_by(Quest, id: uuid, game_id: scope.game.id) do
          nil -> {:error, :not_found}
          quest -> {:ok, quest}
        end

      :error ->
        {:error, :not_found}
    end
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
  Returns a hierarchical tree structure of quests for a game.

  ## Examples

      iex> list_quests_tree_for_game(scope)
      [%{id: "...", name: "Main Quest", children: [%{id: "...", name: "Sub Quest", children: []}]}]

  """
  def list_quests_tree_for_game(%Scope{} = scope) do
    quests =
      from(q in Quest,
        where: q.game_id == ^scope.game.id,
        order_by: [asc: q.name]
      )
      |> Repo.all()

    build_tree(quests)
  end

  defp build_tree(quests) do
    # Group quests by parent_id
    grouped = Enum.group_by(quests, & &1.parent_id)

    # Start with root quests (parent_id is nil)
    root_quests = Map.get(grouped, nil, [])

    # Build tree recursively
    Enum.map(root_quests, fn quest ->
      build_quest_node(quest, grouped)
    end)
  end

  defp build_quest_node(quest, grouped) do
    children =
      grouped
      |> Map.get(quest.id, [])
      |> Enum.map(&build_quest_node(&1, grouped))

    %{
      id: quest.id,
      name: quest.name,
      content: quest.content,
      content_plain_text: quest.content_plain_text,
      tags: quest.tags,
      parent_id: quest.parent_id,
      entity_type: "quest",
      children: children
    }
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
  def link_note(%Scope{} = scope, quest_id, note_id, metadata_attrs \\ %{}) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.link(quest, note, metadata_attrs)
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
  def link_character(%Scope{} = scope, quest_id, character_id, metadata_attrs \\ %{}) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.link(quest, character, metadata_attrs)
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
  def link_faction(%Scope{} = scope, quest_id, faction_id, metadata_attrs \\ %{}) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.link(quest, faction, metadata_attrs)
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
  def link_location(%Scope{} = scope, quest_id, location_id, metadata_attrs \\ %{}) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.link(quest, location, metadata_attrs)
    end
  end

  @doc """
  Links a quest to another quest.
  """
  def link_quest(%Scope{} = scope, quest_id_1, quest_id_2, metadata_attrs \\ %{}) do
    with {:ok, quest_1} <- get_scoped_quest(scope, quest_id_1),
         {:ok, quest_2} <- get_scoped_quest(scope, quest_id_2) do
      Links.link(quest_1, quest_2, metadata_attrs)
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

  def quest_linked?(%Scope{} = scope, quest_id_1, quest_id_2) do
    with {:ok, quest_1} <- get_scoped_quest(scope, quest_id_1),
         {:ok, quest_2} <- get_scoped_quest(scope, quest_id_2) do
      Links.linked?(quest_1, quest_2)
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
  Unlinks a quest from another quest.
  """
  def unlink_quest(%Scope{} = scope, quest_id_1, quest_id_2) do
    with {:ok, quest_1} <- get_scoped_quest(scope, quest_id_1),
         {:ok, quest_2} <- get_scoped_quest(scope, quest_id_2) do
      Links.unlink(quest_1, quest_2)
    end
  end

  @doc """
  Updates a link between a quest and a note.
  """
  def update_link_note(%Scope{} = scope, quest_id, note_id, metadata_attrs) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, note} <- get_scoped_note(scope, note_id) do
      Links.update_link(quest, note, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a quest and a character.
  """
  def update_link_character(%Scope{} = scope, quest_id, character_id, metadata_attrs) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, character} <- get_scoped_character(scope, character_id) do
      Links.update_link(quest, character, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a quest and a faction.
  """
  def update_link_faction(%Scope{} = scope, quest_id, faction_id, metadata_attrs) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, faction} <- get_scoped_faction(scope, faction_id) do
      Links.update_link(quest, faction, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a quest and a location.
  """
  def update_link_location(%Scope{} = scope, quest_id, location_id, metadata_attrs) do
    with {:ok, quest} <- get_scoped_quest(scope, quest_id),
         {:ok, location} <- get_scoped_location(scope, location_id) do
      Links.update_link(quest, location, metadata_attrs)
    end
  end

  @doc """
  Updates a link between a quest and another quest.
  """
  def update_link_quest(%Scope{} = scope, quest_id_1, quest_id_2, metadata_attrs) do
    with {:ok, quest_1} <- get_scoped_quest(scope, quest_id_1),
         {:ok, quest_2} <- get_scoped_quest(scope, quest_id_2) do
      Links.update_link(quest_1, quest_2, metadata_attrs)
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
  Returns all quests linked to a quest.
  """
  def linked_quests(%Scope{} = scope, quest_id) do
    case get_scoped_quest(scope, quest_id) do
      {:ok, quest} ->
        links = Links.links_for(quest)
        Map.get(links, :quests, [])

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

  ## Tag-related functions

  @doc """
  Returns quests filtered by tags.

  ## Examples

      iex> list_quests_by_tags(scope, ["main", "urgent"])
      [%Quest{}, ...]

  """
  def list_quests_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(q in Quest,
      where: q.user_id == ^scope.user.id and fragment("? @> ?", q.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns quests for a game filtered by tags.

  ## Examples

      iex> list_quests_for_game_by_tags(scope, ["main", "urgent"])
      [%Quest{}, ...]

  """
  def list_quests_for_game_by_tags(%Scope{} = scope, tags) when is_list(tags) do
    from(q in Quest,
      where: q.game_id == ^scope.game.id and fragment("? @> ?", q.tags, ^tags)
    )
    |> Repo.all()
  end

  @doc """
  Returns all unique tags used across all quests for a user.

  ## Examples

      iex> list_all_quest_tags(scope)
      ["main", "urgent", "side", "completed"]

  """
  def list_all_quest_tags(%Scope{} = scope) do
    from(q in Quest,
      where: q.user_id == ^scope.user.id,
      select: q.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns all unique tags used across quests for a specific game.

  ## Examples

      iex> list_all_quest_tags_for_game(scope)
      ["main", "urgent", "side"]

  """
  def list_all_quest_tags_for_game(%Scope{} = scope) do
    from(q in Quest,
      where: q.game_id == ^scope.game.id,
      select: q.tags
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  ## Pinning Management

  @doc """
  Pins a quest for a specific game.
  Only users who can access the game can pin its quests.
  """
  def pin_quest(%Scope{} = scope, %Quest{} = quest) do
    with {:ok, %Quest{} = quest} <-
           quest
           |> Quest.changeset(%{pinned: true}, scope, quest.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, quest})
      {:ok, quest}
    end
  end

  @doc """
  Unpins a quest for a specific game.
  Only users who can access the game can unpin its quests.
  """
  def unpin_quest(%Scope{} = scope, %Quest{} = quest) do
    with {:ok, %Quest{} = quest} <-
           quest
           |> Quest.changeset(%{pinned: false}, scope, quest.game_id)
           |> Repo.update() do
      broadcast(scope, {:updated, quest})
      {:ok, quest}
    end
  end

  @doc """
  Lists all pinned quests for a specific game.
  Only users who can access the game can see its pinned quests.
  """
  def list_pinned_quests_for_game(%Scope{} = scope) do
    from(q in Quest, where: q.game_id == ^scope.game.id and q.pinned == true)
    |> Repo.all()
  end
end
