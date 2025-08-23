defmodule GameMasterCore.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games.Game

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
  def list_characters_for_game(%Scope{} = _scope, %Game{} = game) do
    from(c in Character, where: c.game_id == ^game.id)
    |> Repo.all()
  end

  @doc """
  Gets a single character for a specific game.
  Only users who can access the game can access its characters.

  Raises `Ecto.NoResultsError` if the Character does not exist.

  ## Examples

      iex> get_character_for_game!(scope, game, 123)
      %Character{}

      iex> get_character_for_game!(scope, game, 456)
      ** (Ecto.NoResultsError)

  """
  def get_character_for_game!(%Scope{} = _scope, %Game{} = game, id) do
    Repo.get_by!(Character, id: id, game_id: game.id)
  end

  @doc """
  Create a character for a specific game.
  """
  def create_character_for_game(%Scope{} = scope, %Game{} = game, attrs) do
    with {:ok, character = %Character{}} <-
           %Character{}
           |> Character.changeset(attrs, scope, game.id)
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

  def link_note(%Scope{} = scope, %Character{} = character, %Note{} = note) do
  end
end
