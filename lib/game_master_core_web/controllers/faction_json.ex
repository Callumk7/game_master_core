defmodule GameMasterCoreWeb.FactionJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of factions.
  """
  def index(%{factions: factions}) do
    %{data: for(faction <- factions, do: faction_data(faction))}
  end

  @doc """
  Renders a single faction.
  """
  def show(%{faction: faction}) do
    %{data: faction_data(faction)}
  end

  @doc """
  Renders faction links
  """
  def links(%{
        faction: faction,
        notes: notes,
        characters: characters,
        locations: locations,
        quests: quests,
        factions: factions
      }) do
    %{
      data: %{
        faction_id: faction.id,
        faction_name: faction.name,
        links: %{
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          characters: for(character <- characters, do: character_data_with_metadata(character)),
          locations: for(location <- locations, do: location_data_with_metadata(location)),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          factions: for(fact <- factions, do: faction_data_with_metadata(fact))
        }
      }
    }
  end
end
