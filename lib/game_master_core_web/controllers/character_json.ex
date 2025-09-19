defmodule GameMasterCoreWeb.CharacterJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of characters.
  """
  def index(%{characters: characters}) do
    %{data: for(character <- characters, do: character_data(character))}
  end

  @doc """
  Renders a single character.
  """
  def show(%{character: character}) do
    %{data: character_data(character)}
  end

  @doc """
  Renders character links.
  """
  def links(%{
        character: character,
        notes: notes,
        factions: factions,
        locations: locations,
        quests: quests,
        characters: characters
      }) do
    %{
      data: %{
        character_id: character.id,
        character_name: character.name,
        links: %{
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          factions: for(faction <- factions, do: faction_data_with_metadata(faction)),
          locations: for(location <- locations, do: location_data_with_metadata(location)),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          characters: for(char <- characters, do: character_data_with_metadata(char))
        }
      }
    }
  end
end
