defmodule GameMasterCore.Objectives do
  @moduledoc """
  The Objectives context.
  """

  import Ecto.Query, warn: false

  alias GameMasterCore.Repo
  alias GameMasterCore.Quests.Objective
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Quests

  @doc """
  Subscribes to scoped notifications about any objective changes.

  The broadcasted messages match the pattern:

    * {:created, %Objective{}}
    * {:updated, %Objective{}}
    * {:deleted, %Objective{}}

  """
  def subscribe_objectives(%Scope{} = scope) do
    key = scope.game.id

    Phoenix.PubSub.subscribe(GameMasterCore.PubSub, "game:#{key}:objectives")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.game.id

    Phoenix.PubSub.broadcast(GameMasterCore.PubSub, "game:#{key}:objectives", message)
  end

  @doc """
  Returns a list of objectives for a specific quest within a game.
  """
  def list_objectives_for_quest(%Scope{} = scope, quest_id) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(scope, quest_id) do
      objectives =
        from(o in Objective,
          where: o.quest_id == ^quest.id,
          order_by: [asc: o.inserted_at]
        )
        |> Repo.all()

      {:ok, objectives}
    end
  end

  @doc """
  Gets a single objective for a specific quest within a game.
  """
  def get_objective_for_quest!(%Scope{} = scope, quest_id, objective_id) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(scope, quest_id) do
      Repo.get_by!(Objective, id: objective_id, quest_id: quest.id)
    else
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Objective
    end
  end

  @doc """
  Fetches a single objective for a specific quest within a game.

  Returns `{:ok, objective}` if found, `{:error, :not_found}` if not found.
  """
  def fetch_objective_for_quest(%Scope{} = scope, quest_id, objective_id) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(scope, quest_id),
         {:ok, objective_uuid} <- Ecto.UUID.cast(objective_id) do
      case Repo.get_by(Objective, id: objective_uuid, quest_id: quest.id) do
        nil -> {:error, :not_found}
        objective -> {:ok, objective}
      end
    else
      {:error, :not_found} -> {:error, :not_found}
      :error -> {:error, :not_found}
    end
  end

  @doc """
  Creates an objective for a specific quest within a game.
  """
  def create_objective_for_quest(%Scope{} = scope, quest_id, attrs) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(scope, quest_id),
         # Convert to atom keys for consistency
         attrs_normalized <-
           Enum.reduce(attrs, %{}, fn {key, value}, acc ->
             atom_key = if is_binary(key), do: String.to_atom(key), else: key
             Map.put(acc, atom_key, value)
           end),
         attrs_with_quest <- Map.put(attrs_normalized, :quest_id, quest.id),
         {:ok, objective} <-
           %Objective{}
           |> Objective.changeset(attrs_with_quest)
           |> Repo.insert() do
      broadcast(scope, {:created, objective})
      {:ok, objective}
    end
  end

  @doc """
  Updates an objective for a specific quest within a game.
  """
  def update_objective_for_quest(%Scope{} = scope, quest_id, objective_id, attrs) do
    with {:ok, objective} <- fetch_objective_for_quest(scope, quest_id, objective_id),
         # Convert to atom keys for consistency
         attrs_normalized <-
           Enum.reduce(attrs, %{}, fn {key, value}, acc ->
             atom_key = if is_binary(key), do: String.to_atom(key), else: key
             Map.put(acc, atom_key, value)
           end),
         {:ok, updated_objective} <-
           objective
           |> Objective.changeset(attrs_normalized)
           |> Repo.update() do
      broadcast(scope, {:updated, updated_objective})
      {:ok, updated_objective}
    end
  end

  @doc """
  Deletes an objective for a specific quest within a game.
  """
  def delete_objective_for_quest(%Scope{} = scope, quest_id, objective_id) do
    with {:ok, objective} <- fetch_objective_for_quest(scope, quest_id, objective_id),
         {:ok, deleted_objective} <- Repo.delete(objective) do
      broadcast(scope, {:deleted, deleted_objective})
      {:ok, deleted_objective}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking objective changes.
  """
  def change_objective(%Objective{} = objective, attrs \\ %{}) do
    Objective.changeset(objective, attrs)
  end

  @doc """
  Marks an objective as complete.
  """
  def complete_objective(%Scope{} = scope, quest_id, objective_id) do
    update_objective_for_quest(scope, quest_id, objective_id, %{complete: true})
  end

  @doc """
  Marks an objective as incomplete.
  """
  def uncomplete_objective(%Scope{} = scope, quest_id, objective_id) do
    update_objective_for_quest(scope, quest_id, objective_id, %{complete: false})
  end

  @doc """
  Returns all objectives for a specific game.
  """
  def list_objectives_for_game(%Scope{} = scope) do
    from(o in Objective,
      join: q in assoc(o, :quest),
      where: q.game_id == ^scope.game.id,
      order_by: [asc: o.inserted_at],
      preload: [quest: q]
    )
    |> Repo.all()
  end
end
