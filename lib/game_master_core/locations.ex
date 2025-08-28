defmodule GameMasterCore.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any location changes.

  The broadcasted messages match the pattern:

    * {:created, %Location{}}
    * {:updated, %Location{}}
    * {:deleted, %Location{}}

  """
  def subscribe_locations(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "user:#{key}:locations")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "user:#{key}:locations", message)
  end

  def list_locations_for_game(%Scope{} = scope) do
    from(l in Location, where: l.game_id == ^scope.game.id)
    |> Repo.all()
  end

  def get_location_for_game!(%Scope{} = scope, id) do
    Repo.get_by!(Location, id: id, game_id: scope.game.id)
  end

  def create_location_for_game(%Scope{} = scope, attrs) do
    with {:ok, location = %Location{}} <-
           %Location{}
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, location})
      {:ok, location}
    end
  end

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations(scope)
      [%Location{}, ...]

  """
  def list_locations(%Scope{} = scope) do
    Repo.all_by(Location, user_id: scope.user.id)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(scope, 123)
      %Location{}

      iex> get_location!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(%Scope{} = scope, id) do
    Repo.get_by!(Location, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(scope, %{field: value})
      {:ok, %Location{}}

      iex> create_location(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(%Scope{} = scope, attrs) do
    with {:ok, location = %Location{}} <-
           %Location{}
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Repo.insert() do
      broadcast(scope, {:created, location})
      {:ok, location}
    end
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(scope, location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(scope, location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Scope{} = scope, %Location{} = location, attrs) do
    true = location.user_id == scope.user.id

    with {:ok, location = %Location{}} <-
           location
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Repo.update() do
      broadcast(scope, {:updated, location})
      {:ok, location}
    end
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(scope, location)
      {:ok, %Location{}}

      iex> delete_location(scope, location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Scope{} = scope, %Location{} = location) do
    true = location.user_id == scope.user.id

    with {:ok, location = %Location{}} <-
           Repo.delete(location) do
      broadcast(scope, {:deleted, location})
      {:ok, location}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(scope, location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Scope{} = scope, %Location{} = location, attrs \\ %{}) do
    true = location.user_id == scope.user.id

    Location.changeset(location, attrs, scope, scope.game.id)
  end

  ## Location Children

  @doc """
  Returns the list of children for a location.

  ## Examples

      iex> list_children(scope, location)
      [%Location{}, ...]

  """
  def list_children(%Scope{} = _scope, %Location{} = location) do
    Repo.all_by(Location, parent_id: location.id)
  end

  # Child location functions

  @doc """
  Creates a child location.

  ## Examples

      iex> create_child_location(scope, location, %{field: value})
      {:ok, %Location{}}

      iex> create_child_location(scope, location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_child_location(%Scope{} = scope, %Location{} = location, attrs) do
    with {:ok, child = %Location{}} <-
           %Location{}
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Location.put_parent(location)
           |> Repo.insert() do
      broadcast(scope, {:created, child})
      {:ok, child}
    end
  end

  @doc """
  Updates a child location.

  ## Examples

      iex> update_child_location(scope, location, child, %{field: new_value})
      {:ok, %Location{}}

      iex> update_child_location(scope, location, child, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_child_location(%Scope{} = scope, %Location{} = location, %Location{} = child, attrs) do
    with {:ok, child = %Location{}} <-
           child
           |> Location.changeset(attrs, scope, scope.game.id)
           |> Location.put_parent(location)
           |> Repo.update() do
      broadcast(scope, {:updated, child})
      {:ok, child}
    end
  end

  @doc """
  Get all children for a location
  """
  def get_children(%Scope{} = _scope, %Location{} = location) do
    Repo.all_by(Location, parent_id: location.id)
  end
end
