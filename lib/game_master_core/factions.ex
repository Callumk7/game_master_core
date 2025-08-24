defmodule GameMasterCore.Factions do
  @moduledoc """
  The Factions context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any faction changes.

  The broadcasted messages match the pattern:

    * {:created, %Faction{}}
    * {:updated, %Faction{}}
    * {:deleted, %Faction{}}

  """
  def subscribe_factions(%Scope{} = scope) do
    key = scope.game.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "game:#{key}:factions")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.game.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "game:#{key}:factions", message)
  end

  @doc """
  Returns the list of factions.

  ## Examples

      iex> list_factions(scope)
      [%Faction{}, ...]

  """
  def list_factions(%Scope{} = scope) do
    Repo.all_by(Faction, game_id: scope.game.id)
  end

  @doc """
  Gets a single faction.

  Raises `Ecto.NoResultsError` if the Faction does not exist.

  ## Examples

      iex> get_faction!(scope, 123)
      %Faction{}

      iex> get_faction!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_faction!(%Scope{} = scope, id) do
    Repo.get_by!(Faction, id: id, game_id: scope.game.id)
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
    with {:ok, faction = %Faction{}} <-
           %Faction{}
           |> Faction.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, faction})
      {:ok, faction}
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
    true = faction.game_id == scope.game.id

    with {:ok, faction = %Faction{}} <-
           faction
           |> Faction.changeset(attrs, scope)
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
    true = faction.game_id == scope.game.id

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
    true = faction.game_id == scope.game.id

    Faction.changeset(faction, attrs, scope)
  end
end
