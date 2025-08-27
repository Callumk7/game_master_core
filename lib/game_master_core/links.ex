defmodule GameMasterCore.Links do
  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.{Character, CharacterNote, CharacterFaction}
  alias GameMasterCore.Factions.{Faction, FactionNote}
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

      {%Note{} = note, %Faction{} = faction} ->
        create_faction_note_link(faction, note)

      {%Faction{} = faction, %Note{} = note} ->
        create_faction_note_link(faction, note)

      {%Character{} = character, %Faction{} = faction} ->
        create_character_faction_link(character, faction)

      {%Faction{} = faction, %Character{} = character} ->
        create_character_faction_link(character, faction)

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

      {%Note{} = note, %Faction{} = faction} ->
        remove_faction_note_link(faction, note)

      {%Faction{} = faction, %Note{} = note} ->
        remove_faction_note_link(faction, note)

      {%Faction{} = faction, %Character{} = character} ->
        remove_character_faction_link(character, faction)

      {%Character{} = character, %Faction{} = faction} ->
        remove_character_faction_link(character, faction)

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

      {%Note{} = note, %Faction{} = faction} ->
        faction_note_exists?(faction, note)

      {%Faction{} = faction, %Note{} = note} ->
        faction_note_exists?(faction, note)

      {%Faction{} = faction, %Character{} = character} ->
        character_faction_exists?(character, faction)

      {%Character{} = character, %Faction{} = faction} ->
        character_faction_exists?(character, faction)

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
        %{
          notes: get_notes_for_character(character),
          factions: get_factions_for_character(character)
        }

      %Note{} = note ->
        %{characters: get_characters_for_note(note), factions: get_factions_for_note(note)}

      %Faction{} = faction ->
        %{notes: get_notes_for_faction(faction), characters: get_characters_for_faction(faction)}

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

  # Private functions for Faction <-> Note links

  defp create_faction_note_link(faction, note) do
    %FactionNote{}
    |> FactionNote.changeset(%{
      faction_id: faction.id,
      note_id: note.id
    })
    |> Repo.insert()
  end

  defp remove_faction_note_link(faction, note) do
    case Repo.get_by(FactionNote, faction_id: faction.id, note_id: note.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp faction_note_exists?(faction, note) do
    Repo.exists?(
      from facn in FactionNote,
        where: facn.faction_id == ^faction.id and facn.note_id == ^note.id
    )
  end

  defp get_factions_for_note(note) do
    from(f in Faction,
      join: facn in FactionNote,
      on: facn.faction_id == f.id,
      where: facn.note_id == ^note.id
    )
    |> Repo.all()
  end

  defp get_notes_for_faction(faction) do
    from(n in Note,
      join: facn in FactionNote,
      on: facn.note_id == n.id,
      where: facn.faction_id == ^faction.id
    )
    |> Repo.all()
  end

  # Private functions for Character <-> Faction links
  defp create_character_faction_link(character, faction) do
    %CharacterFaction{}
    |> CharacterFaction.changeset(%{
      character_id: character.id,
      faction_id: faction.id
    })
    |> Repo.insert()
  end

  defp remove_character_faction_link(character, faction) do
    case Repo.get_by(CharacterFaction, character_id: character.id, faction_id: faction.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp character_faction_exists?(character, faction) do
    Repo.exists?(
      from fc in CharacterFaction,
        where: fc.character_id == ^character.id and fc.faction_id == ^faction.id
    )
  end

  defp get_factions_for_character(character) do
    from(f in Faction,
      join: fc in CharacterFaction,
      on: fc.faction_id == f.id,
      where: fc.character_id == ^character.id
    )
    |> Repo.all()
  end

  defp get_characters_for_faction(faction) do
    from(c in Character,
      join: fc in CharacterFaction,
      on: fc.character_id == c.id,
      where: fc.faction_id == ^faction.id
    )
    |> Repo.all()
  end
end
