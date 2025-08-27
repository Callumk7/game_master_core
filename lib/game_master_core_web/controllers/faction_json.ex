defmodule GameMasterCoreWeb.FactionJSON do
  alias GameMasterCore.Factions.Faction

  @doc """
  Renders a list of factions.
  """
  def index(%{factions: factions}) do
    %{data: for(faction <- factions, do: data(faction))}
  end

  @doc """
  Renders a single faction.
  """
  def show(%{faction: faction}) do
    %{data: data(faction)}
  end

  @doc """
  Renders faction links
  """
  def links(%{faction: faction, notes: notes, characters: characters}) do
    %{
      data: %{
        faction_id: faction.id,
        faction_name: faction.name,
        links: %{
          notes: for(note <- notes, do: note_data(note)),
          characters: for(character <- characters, do: character_data(character))
        }
      }
    }
  end

  defp data(%Faction{} = faction) do
    %{
      id: faction.id,
      name: faction.name,
      description: faction.description
    }
  end

  defp note_data(note) do
    %{
      id: note.id,
      name: note.name,
      content: note.content
    }
  end

  defp character_data(character) do
    %{
      id: character.id,
      name: character.name,
      description: character.description,
      class: character.class,
      level: character.level,
      image_url: character.image_url
    }
  end
end
