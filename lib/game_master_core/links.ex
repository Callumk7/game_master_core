defmodule GameMasterCore.Links do
  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.{Character, CharacterNote}
  alias GameMasterCore.Notes.Note

  @doc """
  Creates a link between two entities.
  Returns {:ok, link} on success, {:error, changeset} on failure.
  """
  def link(entity1, entity2) do
    case {entity1, entity2} do
      {%Character{} = character, %Note{} = note} ->
        create_character_note_link(character, note)

      {%Note{} = note, %Character{} = character} ->
        create_character_note_link(character, note)

      # Add more entity combinations as needed
      _ ->
        {:error, :unsupported_link_type}
    end
  end

  @doc """
  Removes a link between two entities.
  Returns {:ok, link} on success, {:error, reason} on failure.
  """
  def unlink(entity1, entity2) do
    case {entity1, entity2} do
      {%Character{} = character, %Note{} = note} ->
        remove_character_note_link(character, note)

      {%Note{} = note, %Character{} = character} ->
        remove_character_note_link(character, note)

      _ ->
        {:error, :unsupported_link_type}
    end
  end

  @doc """
  Checks if two entities are linked.
  Returns boolean.
  """
  def linked?(entity1, entity2) do
    case {entity1, entity2} do
      {%Character{} = character, %Note{} = note} ->
        character_note_exists?(character, note)

      {%Note{} = note, %Character{} = character} ->
        character_note_exists?(character, note)

      _ ->
        false
    end
  end

  @doc """
  Gets all linked entities for a given entity.
  Returns a list of linked entities grouped by type.
  """
  def links_for(entity) do
    case entity do
      %Character{} = character ->
        %{notes: get_notes_for_character(character)}

      %Note{} = note ->
        %{characters: get_characters_for_note(note)}

      _ ->
        %{}
    end
  end

  # Private functions for Character <-> Note links

  defp create_character_note_link(character, note) do
    %CharacterNote{}
    |> CharacterNote.changeset(%{
      character_id: character.id,
      note_id: note.id
    })
    |> Repo.insert()
  end

  defp remove_character_note_link(character, note) do
    case Repo.get_by(CharacterNote, character_id: character.id, note_id: note.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp character_note_exists?(character, note) do
    Repo.exists?(
      from cn in CharacterNote,
        where: cn.character_id == ^character.id and cn.note_id == ^note.id
    )
  end

  defp get_notes_for_character(character) do
    from(n in Note,
      join: cn in CharacterNote,
      on: cn.note_id == n.id,
      where: cn.character_id == ^character.id
    )
    |> Repo.all()
  end

  defp get_characters_for_note(note) do
    from(c in Character,
      join: cn in CharacterNote,
      on: cn.character_id == c.id,
      where: cn.note_id == ^note.id
    )
    |> Repo.all()
  end
end
