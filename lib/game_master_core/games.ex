defmodule GameMasterCore.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Notes
  alias GameMasterCore.Factions
  alias GameMasterCore.Characters
  alias GameMasterCore.Locations
  alias GameMasterCore.Quests
  alias GameMasterCore.Repo

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Games.GameMembership
  alias GameMasterCore.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any game changes.

  The broadcasted messages match the pattern:

    * {:created, %Game{}}
    * {:updated, %Game{}}
    * {:deleted, %Game{}}

  """
  def subscribe_games(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:games")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:games", message)
  end

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games(scope)
      [%Game{}, ...]

  """
  def list_games(%Scope{} = scope) do
    user_id = scope.user.id

    from(g in Game,
      left_join: m in GameMembership,
      on: g.id == m.game_id and m.user_id == ^user_id,
      where: g.owner_id == ^user_id or not is_nil(m.id)
    )
    |> Repo.all()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(scope, 123)
      %Game{}

      iex> get_game!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(%Scope{} = scope, id) do
    user_id = scope.user.id

    from(g in Game,
      left_join: m in GameMembership,
      on: g.id == m.game_id and m.user_id == ^user_id,
      where: g.id == ^id and (g.owner_id == ^user_id or not is_nil(m.id))
    )
    |> Repo.one!()
  end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(scope, %{field: value})
      {:ok, %Game{}}

      iex> create_game(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(%Scope{} = scope, attrs) do
    string_attrs =
      attrs
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.into(%{})
      |> Map.put("owner_id", scope.user.id)

    with {:ok, game = %Game{}} <-
           %Game{}
           |> Game.changeset(string_attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, game})
      {:ok, game}
    end
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(scope, game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(scope, game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Scope{} = scope, %Game{} = game, attrs) do
    true = can_modify_game?(scope, game)

    with {:ok, game = %Game{}} <-
           game
           |> Game.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, game})
      {:ok, game}
    end
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(scope, game)
      {:ok, %Game{}}

      iex> delete_game(scope, game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Scope{} = scope, %Game{} = game) do
    true = can_modify_game?(scope, game)

    with {:ok, game = %Game{}} <-
           Repo.delete(game) do
      broadcast(scope, {:deleted, game})
      {:ok, game}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(scope, game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Scope{} = scope, %Game{} = game, attrs \\ %{}) do
    true = can_modify_game?(scope, game)

    Game.changeset(game, attrs, scope)
  end

  @doc """
  Adds a user as a member to a game.
  Only the game owner can add members.
  """
  def add_member(%Scope{} = scope, %Game{} = game, user_id, role \\ "member") do
    if game.owner_id == scope.user.id do
      attrs = %{
        game_id: game.id,
        user_id: user_id,
        role: role
      }

      %GameMembership{}
      |> GameMembership.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Removes a member from a game.
  Only the game owner can remove members.
  """
  def remove_member(%Scope{} = scope, %Game{} = game, user_id) do
    true = game.owner_id == scope.user.id

    case Repo.get_by(GameMembership, game_id: game.id, user_id: user_id) do
      nil -> {:error, :not_found}
      membership -> Repo.delete(membership)
    end
  end

  @doc """
  Lists all members of a game.
  Only accessible by the owner or existing members.
  """
  def list_members(%Scope{} = scope, %Game{} = game) do
    true = can_access_game?(scope, game)

    from(m in GameMembership,
      join: u in assoc(m, :user),
      where: m.game_id == ^game.id,
      select: %{id: m.id, user: u, role: m.role, joined_at: m.inserted_at}
    )
    |> Repo.all()
  end

  @doc """
  Returns all the entities that exist in the game.
  """
  def get_entities(%Scope{} = scope, %Game{} = game) do
    true = can_access_game?(scope, game)

    characters = Characters.list_characters_for_game(scope)
    factions = Factions.list_factions_for_game(scope)
    notes = Notes.list_notes_for_game(scope)
    quests = Quests.list_quests_for_game(scope)
    locations = Locations.list_locations_for_game(scope)

    %{
      notes: notes,
      characters: characters,
      factions: factions,
      locations: locations,
      quests: quests
    }
  end

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
end
