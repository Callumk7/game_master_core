defmodule GameMasterCoreWeb.QuestJSON do
  import GameMasterCoreWeb.JSONHelpers
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

  @doc """
  Renders quest links.
  """
  def links(%{quest: quest, characters: characters, factions: factions, notes: notes, locations: locations}) do
    %{
      data: %{
        quest_id: quest.id,
        quest_name: quest.name,
        links: %{
          characters: for(character <- characters, do: character_data(character)),
          factions: for(faction <- factions, do: faction_data(faction)),
          notes: for(note <- notes, do: note_data(note)),
          locations: for(location <- locations, do: location_data(location))
        }
      }
    }
  end

  defp data(%Quest{} = quest) do
    %{
      id: quest.id,
      name: quest.name,
      content: quest.content
    }
  end
end
