defmodule GameMasterCoreWeb.NoteJSON do
  alias GameMasterCore.Notes.Note

  @doc """
  Renders a list of notes.
  """
  def index(%{notes: notes}) do
    %{data: for(note <- notes, do: data(note))}
  end

  @doc """
  Renders a single note.
  """
  def show(%{note: note}) do
    %{data: data(note)}
  end

  @doc """
  Renders a list of links for a note.
  """
  def links(%{note: note, characters: characters, factions: factions}) do
    %{
      data: %{
        note_id: note.id,
        note_name: note.name,
        links: %{
          characters: for(character <- characters, do: character_data(character)),
          factions: for(faction <- factions, do: faction_data(faction))
        }
      }
    }
  end

  defp data(%Note{} = note) do
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
      level: character.level,
      class: character.class
    }
  end

  defp faction_data(faction) do
    %{
      id: faction.id,
      name: faction.name,
      description: faction.description
    }
  end
end
