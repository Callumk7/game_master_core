defmodule GameMasterCore.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Games.Game
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
    Repo.all_by(Game, owner_id: scope.user.id)
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
    Repo.get_by!(Game, id: id, owner_id: scope.user.id)
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
    attrs_with_owner = Map.put(attrs, "owner_id", scope.user.id)

    with {:ok, game = %Game{}} <-
           %Game{}
           |> Game.changeset(attrs_with_owner, scope)
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
    true = game.owner_id == scope.user.id

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
    true = game.owner_id == scope.user.id

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
    true = game.owner_id == scope.user.id

    Game.changeset(game, attrs, scope)
  end
end
