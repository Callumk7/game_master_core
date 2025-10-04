defmodule GameMasterCoreWeb.ObjectiveJSON do
  alias GameMasterCore.Quests.Objective

  @doc """
  Renders a list of objectives.
  """
  def index(%{objectives: objectives}) do
    %{data: for(objective <- objectives, do: data(objective))}
  end

  @doc """
  Renders a single objective.
  """
  def show(%{objective: objective}) do
    %{data: data(objective)}
  end

  defp data(%Objective{} = objective) do
    %{
      id: objective.id,
      body: objective.body,
      complete: objective.complete,
      quest_id: objective.quest_id,
      note_link_id: objective.note_link_id,
      inserted_at: objective.inserted_at,
      updated_at: objective.updated_at
    }
  end
end
