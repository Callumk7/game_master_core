defmodule GameMasterCoreWeb.QuestJSON do
  alias GameMasterCore.Quests.Quest

  @doc """
  Renders a list of quests.
  """
  def index(%{quests: quests}) do
    %{data: for(quest <- quests, do: data(quest))}
  end

  @doc """
  Renders a single quest.
  """
  def show(%{quest: quest}) do
    %{data: data(quest)}
  end

  defp data(%Quest{} = quest) do
    %{
      id: quest.id,
      name: quest.name,
      content: quest.content
    }
  end
end
