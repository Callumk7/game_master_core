defmodule GameMasterCoreWeb.LocationJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of locations.
  """
  def index(%{locations: locations}) do
    %{data: for(location <- locations, do: location_data(location))}
  end

  @doc """
  Renders a single location.
  """
  def show(%{location: location}) do
    %{data: location_data(location)}
  end

  def links(%{
        location: location,
        notes: notes,
        factions: factions,
        characters: characters,
        quests: quests
      }) do
    %{
      data: %{
        location_id: location.id,
        location_name: location.name,
        location_type: location.type,
        links: %{
          notes: for(note <- notes, do: note_data(note)),
          factions: for(faction <- factions, do: faction_data(faction)),
          characters: for(character <- characters, do: character_data(character)),
          quests: for(quest <- quests, do: quest_data(quest))
        }
      }
    }
  end
end
