defmodule GameMasterCore.Links do
  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.{Character, CharacterNote, CharacterFaction, CharacterLocation}
  alias GameMasterCore.Factions.{Faction, FactionNote, FactionLocation}
  alias GameMasterCore.Notes.Note
  alias GameMasterCore.Locations.{Location, LocationNote}
  alias GameMasterCore.Quests.{Quest, QuestCharacter, QuestFaction, QuestLocation, QuestNote}

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

      {%Location{} = location, %Note{} = note} ->
        create_location_note_link(location, note)

      {%Location{} = location, %Character{} = character} ->
        create_character_location_link(character, location)

      {%Location{} = location, %Faction{} = faction} ->
        create_faction_location_link(faction, location)

      {%Note{} = note, %Location{} = location} ->
        create_location_note_link(location, note)

      {%Character{} = character, %Location{} = location} ->
        create_character_location_link(character, location)

      {%Faction{} = faction, %Location{} = location} ->
        create_faction_location_link(faction, location)

      {%Quest{} = quest, %Character{} = character} ->
        create_quest_character_link(quest, character)

      {%Character{} = character, %Quest{} = quest} ->
        create_quest_character_link(quest, character)

      {%Quest{} = quest, %Faction{} = faction} ->
        create_quest_faction_link(quest, faction)

      {%Faction{} = faction, %Quest{} = quest} ->
        create_quest_faction_link(quest, faction)

      {%Quest{} = quest, %Location{} = location} ->
        create_quest_location_link(quest, location)

      {%Location{} = location, %Quest{} = quest} ->
        create_quest_location_link(quest, location)

      {%Quest{} = quest, %Note{} = note} ->
        create_quest_note_link(quest, note)

      {%Note{} = note, %Quest{} = quest} ->
        create_quest_note_link(quest, note)

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

      {%Location{} = location, %Note{} = note} ->
        remove_location_note_link(location, note)

      {%Location{} = location, %Character{} = character} ->
        remove_character_location_link(character, location)

      {%Location{} = location, %Faction{} = faction} ->
        remove_faction_location_link(faction, location)

      {%Note{} = note, %Location{} = location} ->
        remove_location_note_link(location, note)

      {%Character{} = character, %Location{} = location} ->
        remove_character_location_link(character, location)

      {%Faction{} = faction, %Location{} = location} ->
        remove_faction_location_link(faction, location)

      {%Quest{} = quest, %Character{} = character} ->
        remove_quest_character_link(quest, character)

      {%Character{} = character, %Quest{} = quest} ->
        remove_quest_character_link(quest, character)

      {%Quest{} = quest, %Faction{} = faction} ->
        remove_quest_faction_link(quest, faction)

      {%Faction{} = faction, %Quest{} = quest} ->
        remove_quest_faction_link(quest, faction)

      {%Quest{} = quest, %Location{} = location} ->
        remove_quest_location_link(quest, location)

      {%Location{} = location, %Quest{} = quest} ->
        remove_quest_location_link(quest, location)

      {%Quest{} = quest, %Note{} = note} ->
        remove_quest_note_link(quest, note)

      {%Note{} = note, %Quest{} = quest} ->
        remove_quest_note_link(quest, note)

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

      {%Location{} = location, %Note{} = note} ->
        location_note_exists?(location, note)

      {%Location{} = location, %Character{} = character} ->
        character_location_exists?(character, location)

      {%Location{} = location, %Faction{} = faction} ->
        faction_location_exists?(faction, location)

      {%Note{} = note, %Location{} = location} ->
        location_note_exists?(location, note)

      {%Character{} = character, %Location{} = location} ->
        character_location_exists?(character, location)

      {%Faction{} = faction, %Location{} = location} ->
        faction_location_exists?(faction, location)

      {%Quest{} = quest, %Character{} = character} ->
        quest_character_exists?(quest, character)

      {%Character{} = character, %Quest{} = quest} ->
        quest_character_exists?(quest, character)

      {%Quest{} = quest, %Faction{} = faction} ->
        quest_faction_exists?(quest, faction)

      {%Faction{} = faction, %Quest{} = quest} ->
        quest_faction_exists?(quest, faction)

      {%Quest{} = quest, %Location{} = location} ->
        quest_location_exists?(quest, location)

      {%Location{} = location, %Quest{} = quest} ->
        quest_location_exists?(quest, location)

      {%Quest{} = quest, %Note{} = note} ->
        quest_note_exists?(quest, note)

      {%Note{} = note, %Quest{} = quest} ->
        quest_note_exists?(quest, note)

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
          factions: get_factions_for_character(character),
          locations: get_locations_for_character(character),
          quests: get_quests_for_character(character)
        }

      %Note{} = note ->
        %{
          characters: get_characters_for_note(note),
          factions: get_factions_for_note(note),
          locations: get_locations_for_note(note),
          quests: get_quests_for_note(note)
        }

      %Faction{} = faction ->
        %{
          notes: get_notes_for_faction(faction),
          characters: get_characters_for_faction(faction),
          locations: get_locations_for_faction(faction),
          quests: get_quests_for_faction(faction)
        }

      %Location{} = location ->
        %{
          notes: get_notes_for_location(location),
          characters: get_characters_for_location(location),
          factions: get_factions_for_location(location),
          quests: get_quests_for_location(location)
        }

      %Quest{} = quest ->
        %{
          notes: get_notes_for_quest(quest),
          characters: get_characters_for_quest(quest),
          factions: get_factions_for_quest(quest),
          locations: get_locations_for_quest(quest)
        }

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

  # Private functions for Location <-> Note links

  defp create_location_note_link(location, note) do
    %LocationNote{}
    |> LocationNote.changeset(%{
      location_id: location.id,
      note_id: note.id
    })
    |> Repo.insert()
  end

  defp remove_location_note_link(location, note) do
    case Repo.get_by(LocationNote, location_id: location.id, note_id: note.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp location_note_exists?(location, note) do
    Repo.exists?(
      from ln in LocationNote,
        where: ln.location_id == ^location.id and ln.note_id == ^note.id
    )
  end

  defp get_notes_for_location(location) do
    from(n in Note,
      join: ln in LocationNote,
      on: ln.note_id == n.id,
      where: ln.location_id == ^location.id
    )
    |> Repo.all()
  end

  defp get_locations_for_note(note) do
    from(l in Location,
      join: ln in LocationNote,
      on: ln.location_id == l.id,
      where: ln.note_id == ^note.id
    )
    |> Repo.all()
  end

  # Private functions for Character <-> Location links

  defp create_character_location_link(character, location) do
    %CharacterLocation{}
    |> CharacterLocation.changeset(%{
      character_id: character.id,
      location_id: location.id
    })
    |> Repo.insert()
  end

  defp remove_character_location_link(character, location) do
    case Repo.get_by(CharacterLocation, character_id: character.id, location_id: location.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp character_location_exists?(character, location) do
    Repo.exists?(
      from cl in CharacterLocation,
        where: cl.character_id == ^character.id and cl.location_id == ^location.id
    )
  end

  defp get_locations_for_character(character) do
    from(l in Location,
      join: cl in CharacterLocation,
      on: cl.location_id == l.id,
      where: cl.character_id == ^character.id
    )
    |> Repo.all()
  end

  defp get_characters_for_location(location) do
    from(c in Character,
      join: cl in CharacterLocation,
      on: cl.character_id == c.id,
      where: cl.location_id == ^location.id
    )
    |> Repo.all()
  end

  # Private functions for Faction <-> Location links
  defp create_faction_location_link(faction, location) do
    %FactionLocation{}
    |> FactionLocation.changeset(%{
      faction_id: faction.id,
      location_id: location.id
    })
    |> Repo.insert()
  end

  defp remove_faction_location_link(faction, location) do
    case Repo.get_by(FactionLocation, faction_id: faction.id, location_id: location.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp faction_location_exists?(faction, location) do
    Repo.exists?(
      from fl in FactionLocation,
        where: fl.faction_id == ^faction.id and fl.location_id == ^location.id
    )
  end

  defp get_factions_for_location(location) do
    from(f in Faction,
      join: fl in FactionLocation,
      on: fl.faction_id == f.id,
      where: fl.location_id == ^location.id
    )
    |> Repo.all()
  end

  defp get_locations_for_faction(faction) do
    from(l in Location,
      join: fl in FactionLocation,
      on: fl.location_id == l.id,
      where: fl.faction_id == ^faction.id
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Character links
  defp create_quest_character_link(quest, character) do
    %QuestCharacter{}
    |> QuestCharacter.changeset(%{
      quest_id: quest.id,
      character_id: character.id
    })
    |> Repo.insert()
  end

  defp remove_quest_character_link(quest, character) do
    case Repo.get_by(QuestCharacter, quest_id: quest.id, character_id: character.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp quest_character_exists?(quest, character) do
    Repo.exists?(
      from qc in QuestCharacter,
        where: qc.quest_id == ^quest.id and qc.character_id == ^character.id
    )
  end

  defp get_quests_for_character(character) do
    from(q in Quest,
      join: qc in QuestCharacter,
      on: qc.quest_id == q.id,
      where: qc.character_id == ^character.id
    )
    |> Repo.all()
  end

  defp get_characters_for_quest(quest) do
    from(c in Character,
      join: qc in QuestCharacter,
      on: qc.character_id == c.id,
      where: qc.quest_id == ^quest.id
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Faction links
  defp create_quest_faction_link(quest, faction) do
    %QuestFaction{}
    |> QuestFaction.changeset(%{
      quest_id: quest.id,
      faction_id: faction.id
    })
    |> Repo.insert()
  end

  defp remove_quest_faction_link(quest, faction) do
    case Repo.get_by(QuestFaction, quest_id: quest.id, faction_id: faction.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp quest_faction_exists?(quest, faction) do
    Repo.exists?(
      from qf in QuestFaction,
        where: qf.quest_id == ^quest.id and qf.faction_id == ^faction.id
    )
  end

  defp get_factions_for_quest(quest) do
    from(f in Faction,
      join: qf in QuestFaction,
      on: qf.faction_id == f.id,
      where: qf.quest_id == ^quest.id
    )
    |> Repo.all()
  end

  defp get_quests_for_faction(faction) do
    from(q in Quest,
      join: qf in QuestFaction,
      on: qf.quest_id == q.id,
      where: qf.faction_id == ^faction.id
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Location links
  defp create_quest_location_link(quest, location) do
    %QuestLocation{}
    |> QuestLocation.changeset(%{
      quest_id: quest.id,
      location_id: location.id
    })
    |> Repo.insert()
  end

  defp remove_quest_location_link(quest, location) do
    case Repo.get_by(QuestLocation, quest_id: quest.id, location_id: location.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp quest_location_exists?(quest, location) do
    Repo.exists?(
      from ql in QuestLocation,
        where: ql.quest_id == ^quest.id and ql.location_id == ^location.id
    )
  end

  defp get_locations_for_quest(quest) do
    from(l in Location,
      join: ql in QuestLocation,
      on: ql.location_id == l.id,
      where: ql.quest_id == ^quest.id
    )
    |> Repo.all()
  end

  defp get_quests_for_location(location) do
    from(q in Quest,
      join: ql in QuestLocation,
      on: ql.quest_id == q.id,
      where: ql.location_id == ^location.id
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Note links
  defp create_quest_note_link(quest, note) do
    %QuestNote{}
    |> QuestNote.changeset(%{
      quest_id: quest.id,
      note_id: note.id
    })
    |> Repo.insert()
  end

  defp remove_quest_note_link(quest, note) do
    case Repo.get_by(QuestNote, quest_id: quest.id, note_id: note.id) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  defp quest_note_exists?(quest, note) do
    Repo.exists?(
      from qn in QuestNote,
        where: qn.quest_id == ^quest.id and qn.note_id == ^note.id
    )
  end

  defp get_notes_for_quest(quest) do
    from(n in Note,
      join: qn in QuestNote,
      on: qn.note_id == n.id,
      where: qn.quest_id == ^quest.id
    )
    |> Repo.all()
  end

  defp get_quests_for_note(note) do
    from(q in Quest,
      join: qn in QuestNote,
      on: qn.quest_id == q.id,
      where: qn.note_id == ^note.id
    )
    |> Repo.all()
  end
end
