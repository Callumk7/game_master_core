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

  defp data(%Note{} = note) do
    %{
      id: note.id,
      name: note.name,
      content: note.content
    }
  end
end
