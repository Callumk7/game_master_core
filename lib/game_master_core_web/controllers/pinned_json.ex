defmodule GameMasterCoreWeb.PinnedJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders all pinned entities for a game.
  """
  def index(%{
        game_id: game_id,
        characters: characters,
        notes: notes,
        factions: factions,
        locations: locations,
        quests: quests
      }) do
    %{
      data: %{
        game_id: game_id,
        pinned_entities: %{
          characters: for(character <- characters, do: character_data(character)),
          notes: for(note <- notes, do: note_data(note)),
          factions: for(faction <- factions, do: faction_data(faction)),
          locations: for(location <- locations, do: location_data(location)),
          quests: for(quest <- quests, do: quest_data(quest))
        },
        total_count:
          length(characters) + length(notes) + length(factions) + length(locations) +
            length(quests)
      }
    }
  end
end
