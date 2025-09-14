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
          notes: for(note <- notes, do: note_data(note)),
          factions: for(faction <- factions, do: faction_data(faction)),
          locations: for(location <- locations, do: location_data(location)),
          quests: for(quest <- quests, do: quest_data(quest)),
          characters: for(char <- characters, do: character_data(char))
        }
      }
    }
  end
end
