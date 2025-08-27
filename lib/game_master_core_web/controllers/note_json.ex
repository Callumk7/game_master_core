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
  def links(%{note: note, characters: characters, factions: factions}) do
    %{
      data: %{
        note_id: note.id,
        note_name: note.name,
        links: %{
          characters: for(character <- characters, do: character_summary_data(character)),
          factions: for(faction <- factions, do: faction_data(faction))
        }
      }
    }
  end
end
