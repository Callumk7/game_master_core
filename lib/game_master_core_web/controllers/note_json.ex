defmodule GameMasterCoreWeb.NoteJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of notes.
  """
  def index(%{notes: notes}) do
    %{data: for(note <- notes, do: note_data(note))}
  end

  @doc """
  Renders a single note.
  """
  def show(%{note: note}) do
    %{data: note_data(note)}
  end

  @doc """
  Renders a list of links for a note.
  """
  def links(%{
        note: note,
        characters: characters,
        factions: factions,
        locations: locations,
        quests: quests,
        notes: notes
      }) do
    %{
      data: %{
        note_id: note.id,
        note_name: note.name,
        links: %{
          characters: for(character <- characters, do: character_summary_data(character)),
          factions: for(faction <- factions, do: faction_data(faction)),
          locations: for(location <- locations, do: location_data(location)),
          quests: for(quest <- quests, do: quest_data(quest)),
          notes: for(n <- notes, do: note_data(n))
        }
      }
    }
  end
end
