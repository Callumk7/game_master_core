defmodule GameMasterCore.Links do
  import Ecto.Query, warn: false
  alias GameMasterCore.Repo

  alias GameMasterCore.Characters.{
    Character,
    CharacterNote,
    CharacterFaction,
    CharacterLocation,
    CharacterCharacter
  }

  alias GameMasterCore.Factions.{Faction, FactionNote, FactionLocation, FactionFaction}
  alias GameMasterCore.Notes.{Note, NoteNote}
  alias GameMasterCore.Locations.{Location, LocationNote, LocationLocation}

  alias GameMasterCore.Quests.{
    Quest,
    QuestCharacter,
    QuestFaction,
    QuestLocation,
    QuestNote,
    QuestQuest
  }

  @doc """
  Creates multiple links from a source entity to multiple target entities.

  Takes a source entity and a list of `{target_entity, metadata_attrs}` tuples.
  All links are created or none are (fail-fast behavior).

  ## Examples

      iex> create_multiple_links(character, [
        {faction, %{is_primary: true, faction_role: "Leader"}},
        {location, %{is_current_location: true}}
      ])
      {:ok, [%CharacterFaction{}, %CharacterLocation{}]}
      
      iex> create_multiple_links(character, [{invalid_entity, %{}}])
      {:error, :unsupported_link_type}
  """
  def create_multiple_links(_source_entity, []), do: {:ok, []}

  def create_multiple_links(source_entity, target_entities_with_metadata)
      when is_list(target_entities_with_metadata) do
    results =
      Enum.map(target_entities_with_metadata, fn {target_entity, metadata_attrs} ->
        link(source_entity, target_entity, metadata_attrs)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(results, fn {:ok, link} -> link end)}

      error ->
        error
    end
  end

  @doc """
  Creates a link between two entities.
  Returns {:ok, link} on success, {:error, changeset} on failure.
  """
  def link(entity1, entity2, metadata_attrs \\ %{}) do
    case {entity1, entity2} do
      {%Character{} = character, %Note{} = note} ->
        create_character_note_link(character, note, metadata_attrs)

      {%Note{} = note, %Character{} = character} ->
        create_character_note_link(character, note, metadata_attrs)

      {%Note{} = note, %Faction{} = faction} ->
        create_faction_note_link(faction, note, metadata_attrs)

      {%Faction{} = faction, %Note{} = note} ->
        create_faction_note_link(faction, note, metadata_attrs)

      {%Character{} = character, %Faction{} = faction} ->
        create_character_faction_link(character, faction, metadata_attrs)

      {%Faction{} = faction, %Character{} = character} ->
        create_character_faction_link(character, faction, metadata_attrs)

      {%Location{} = location, %Note{} = note} ->
        create_location_note_link(location, note, metadata_attrs)

      {%Location{} = location, %Character{} = character} ->
        create_character_location_link(character, location, metadata_attrs)

      {%Location{} = location, %Faction{} = faction} ->
        create_faction_location_link(faction, location, metadata_attrs)

      {%Note{} = note, %Location{} = location} ->
        create_location_note_link(location, note, metadata_attrs)

      {%Character{} = character, %Location{} = location} ->
        create_character_location_link(character, location, metadata_attrs)

      {%Faction{} = faction, %Location{} = location} ->
        create_faction_location_link(faction, location, metadata_attrs)

      {%Quest{} = quest, %Character{} = character} ->
        create_quest_character_link(quest, character, metadata_attrs)

      {%Character{} = character, %Quest{} = quest} ->
        create_quest_character_link(quest, character, metadata_attrs)

      {%Quest{} = quest, %Faction{} = faction} ->
        create_quest_faction_link(quest, faction, metadata_attrs)

      {%Faction{} = faction, %Quest{} = quest} ->
        create_quest_faction_link(quest, faction, metadata_attrs)

      {%Quest{} = quest, %Location{} = location} ->
        create_quest_location_link(quest, location, metadata_attrs)

      {%Location{} = location, %Quest{} = quest} ->
        create_quest_location_link(quest, location, metadata_attrs)

      {%Quest{} = quest, %Note{} = note} ->
        create_quest_note_link(quest, note, metadata_attrs)

      {%Note{} = note, %Quest{} = quest} ->
        create_quest_note_link(quest, note, metadata_attrs)

      # Self-join relationships
      {%Character{} = character1, %Character{} = character2} ->
        create_character_character_link(character1, character2, metadata_attrs)

      {%Faction{} = faction1, %Faction{} = faction2} ->
        create_faction_faction_link(faction1, faction2, metadata_attrs)

      {%Location{} = location1, %Location{} = location2} ->
        create_location_location_link(location1, location2, metadata_attrs)

      {%Quest{} = quest1, %Quest{} = quest2} ->
        create_quest_quest_link(quest1, quest2, metadata_attrs)

      {%Note{} = note1, %Note{} = note2} ->
        create_note_note_link(note1, note2, metadata_attrs)

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

      # Self-join relationships
      {%Character{} = character1, %Character{} = character2} ->
        remove_character_character_link(character1, character2)

      {%Faction{} = faction1, %Faction{} = faction2} ->
        remove_faction_faction_link(faction1, faction2)

      {%Location{} = location1, %Location{} = location2} ->
        remove_location_location_link(location1, location2)

      {%Quest{} = quest1, %Quest{} = quest2} ->
        remove_quest_quest_link(quest1, quest2)

      {%Note{} = note1, %Note{} = note2} ->
        remove_note_note_link(note1, note2)

      _ ->
        {:error, :unsupported_link_type}
    end
  end

  @doc """
  Updates an existing link between two entities.
  Returns {:ok, link} on success, {:error, reason} on failure.
  """
  def update_link(entity1, entity2, metadata_attrs) do
    case {entity1, entity2} do
      {%Character{} = character, %Note{} = note} ->
        update_character_note_link(character, note, metadata_attrs)

      {%Note{} = note, %Character{} = character} ->
        update_character_note_link(character, note, metadata_attrs)

      {%Note{} = note, %Faction{} = faction} ->
        update_faction_note_link(faction, note, metadata_attrs)

      {%Faction{} = faction, %Note{} = note} ->
        update_faction_note_link(faction, note, metadata_attrs)

      {%Character{} = character, %Faction{} = faction} ->
        update_character_faction_link(character, faction, metadata_attrs)

      {%Faction{} = faction, %Character{} = character} ->
        update_character_faction_link(character, faction, metadata_attrs)

      {%Location{} = location, %Note{} = note} ->
        update_location_note_link(location, note, metadata_attrs)

      {%Location{} = location, %Character{} = character} ->
        update_character_location_link(character, location, metadata_attrs)

      {%Location{} = location, %Faction{} = faction} ->
        update_faction_location_link(faction, location, metadata_attrs)

      {%Note{} = note, %Location{} = location} ->
        update_location_note_link(location, note, metadata_attrs)

      {%Character{} = character, %Location{} = location} ->
        update_character_location_link(character, location, metadata_attrs)

      {%Faction{} = faction, %Location{} = location} ->
        update_faction_location_link(faction, location, metadata_attrs)

      {%Quest{} = quest, %Character{} = character} ->
        update_quest_character_link(quest, character, metadata_attrs)

      {%Character{} = character, %Quest{} = quest} ->
        update_quest_character_link(quest, character, metadata_attrs)

      {%Quest{} = quest, %Faction{} = faction} ->
        update_quest_faction_link(quest, faction, metadata_attrs)

      {%Faction{} = faction, %Quest{} = quest} ->
        update_quest_faction_link(quest, faction, metadata_attrs)

      {%Quest{} = quest, %Location{} = location} ->
        update_quest_location_link(quest, location, metadata_attrs)

      {%Location{} = location, %Quest{} = quest} ->
        update_quest_location_link(quest, location, metadata_attrs)

      {%Quest{} = quest, %Note{} = note} ->
        update_quest_note_link(quest, note, metadata_attrs)

      {%Note{} = note, %Quest{} = quest} ->
        update_quest_note_link(quest, note, metadata_attrs)

      # Self-join relationships
      {%Character{} = character1, %Character{} = character2} ->
        update_character_character_link(character1, character2, metadata_attrs)

      {%Faction{} = faction1, %Faction{} = faction2} ->
        update_faction_faction_link(faction1, faction2, metadata_attrs)

      {%Location{} = location1, %Location{} = location2} ->
        update_location_location_link(location1, location2, metadata_attrs)

      {%Quest{} = quest1, %Quest{} = quest2} ->
        update_quest_quest_link(quest1, quest2, metadata_attrs)

      {%Note{} = note1, %Note{} = note2} ->
        update_note_note_link(note1, note2, metadata_attrs)

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

      # Self-join relationships
      {%Character{} = character1, %Character{} = character2} ->
        character_character_exists?(character1, character2)

      {%Faction{} = faction1, %Faction{} = faction2} ->
        faction_faction_exists?(faction1, faction2)

      {%Location{} = location1, %Location{} = location2} ->
        location_location_exists?(location1, location2)

      {%Quest{} = quest1, %Quest{} = quest2} ->
        quest_quest_exists?(quest1, quest2)

      {%Note{} = note1, %Note{} = note2} ->
        note_note_exists?(note1, note2)

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
          quests: get_quests_for_character(character),
          characters: get_characters_for_character(character)
        }

      %Note{} = note ->
        %{
          characters: get_characters_for_note(note),
          factions: get_factions_for_note(note),
          locations: get_locations_for_note(note),
          quests: get_quests_for_note(note),
          notes: get_notes_for_note(note)
        }

      %Faction{} = faction ->
        %{
          notes: get_notes_for_faction(faction),
          characters: get_characters_for_faction(faction),
          locations: get_locations_for_faction(faction),
          quests: get_quests_for_faction(faction),
          factions: get_factions_for_faction(faction)
        }

      %Location{} = location ->
        %{
          notes: get_notes_for_location(location),
          characters: get_characters_for_location(location),
          factions: get_factions_for_location(location),
          quests: get_quests_for_location(location),
          locations: get_locations_for_location(location)
        }

      %Quest{} = quest ->
        %{
          notes: get_notes_for_quest(quest),
          characters: get_characters_for_quest(quest),
          factions: get_factions_for_quest(quest),
          locations: get_locations_for_quest(quest),
          quests: get_quests_for_quest(quest)
        }

      _ ->
        %{}
    end
  end

  # Private functions for Character <-> Note links

  defp create_character_note_link(character, note, metadata_attrs) do
    changeset_attrs =
      %{
        character_id: character.id,
        note_id: note.id
      }
      |> Map.merge(metadata_attrs)

    %CharacterNote{}
    |> CharacterNote.changeset(changeset_attrs)
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
      where: cn.character_id == ^character.id,
      select: %{
        entity: n,
        relationship_type: cn.relationship_type,
        description: cn.description,
        strength: cn.strength,
        is_active: cn.is_active,
        metadata: cn.metadata
      }
    )
    |> Repo.all()
  end

  defp get_characters_for_note(note) do
    from(c in Character,
      join: cn in CharacterNote,
      on: cn.character_id == c.id,
      where: cn.note_id == ^note.id,
      select: %{
        entity: c,
        relationship_type: cn.relationship_type,
        description: cn.description,
        strength: cn.strength,
        is_active: cn.is_active,
        metadata: cn.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Faction <-> Note links

  defp create_faction_note_link(faction, note, metadata_attrs) do
    changeset_attrs =
      %{
        faction_id: faction.id,
        note_id: note.id
      }
      |> Map.merge(metadata_attrs)

    %FactionNote{}
    |> FactionNote.changeset(changeset_attrs)
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
      where: facn.note_id == ^note.id,
      select: %{
        entity: f,
        relationship_type: facn.relationship_type,
        description: facn.description,
        strength: facn.strength,
        is_active: facn.is_active,
        metadata: facn.metadata
      }
    )
    |> Repo.all()
  end

  defp get_notes_for_faction(faction) do
    from(n in Note,
      join: facn in FactionNote,
      on: facn.note_id == n.id,
      where: facn.faction_id == ^faction.id,
      select: %{
        entity: n,
        relationship_type: facn.relationship_type,
        description: facn.description,
        strength: facn.strength,
        is_active: facn.is_active,
        metadata: facn.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Character <-> Faction links

  defp create_character_faction_link(character, faction, metadata_attrs) do
    changeset_attrs =
      %{
        character_id: character.id,
        faction_id: faction.id
      }
      |> Map.merge(metadata_attrs)

    %CharacterFaction{}
    |> CharacterFaction.changeset(changeset_attrs)
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
      where: fc.character_id == ^character.id,
      select: %{
        entity: f,
        relationship_type: fc.relationship_type,
        description: fc.description,
        strength: fc.strength,
        is_active: fc.is_active,
        is_primary: fc.is_primary,
        faction_role: fc.faction_role,
        metadata: fc.metadata
      }
    )
    |> Repo.all()
  end

  defp get_characters_for_faction(faction) do
    from(c in Character,
      join: fc in CharacterFaction,
      on: fc.character_id == c.id,
      where: fc.faction_id == ^faction.id,
      select: %{
        entity: c,
        relationship_type: fc.relationship_type,
        description: fc.description,
        strength: fc.strength,
        is_active: fc.is_active,
        is_primary: fc.is_primary,
        faction_role: fc.faction_role,
        metadata: fc.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Location <-> Note links

  defp create_location_note_link(location, note, metadata_attrs) do
    changeset_attrs =
      %{
        location_id: location.id,
        note_id: note.id
      }
      |> Map.merge(metadata_attrs)

    %LocationNote{}
    |> LocationNote.changeset(changeset_attrs)
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
      where: ln.location_id == ^location.id,
      select: %{
        entity: n,
        relationship_type: ln.relationship_type,
        description: ln.description,
        strength: ln.strength,
        is_active: ln.is_active,
        metadata: ln.metadata
      }
    )
    |> Repo.all()
  end

  defp get_locations_for_note(note) do
    from(l in Location,
      join: ln in LocationNote,
      on: ln.location_id == l.id,
      where: ln.note_id == ^note.id,
      select: %{
        entity: l,
        relationship_type: ln.relationship_type,
        description: ln.description,
        strength: ln.strength,
        is_active: ln.is_active,
        metadata: ln.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Character <-> Location links

  defp create_character_location_link(character, location, metadata_attrs) do
    changeset_attrs =
      %{
        character_id: character.id,
        location_id: location.id
      }
      |> Map.merge(metadata_attrs)

    %CharacterLocation{}
    |> CharacterLocation.changeset(changeset_attrs)
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
      where: cl.character_id == ^character.id,
      select: %{
        entity: l,
        relationship_type: cl.relationship_type,
        description: cl.description,
        strength: cl.strength,
        is_active: cl.is_active,
        is_current_location: cl.is_current_location,
        metadata: cl.metadata
      }
    )
    |> Repo.all()
  end

  defp get_characters_for_location(location) do
    from(c in Character,
      join: cl in CharacterLocation,
      on: cl.character_id == c.id,
      where: cl.location_id == ^location.id,
      select: %{
        entity: c,
        relationship_type: cl.relationship_type,
        description: cl.description,
        strength: cl.strength,
        is_active: cl.is_active,
        is_current_location: cl.is_current_location,
        metadata: cl.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Faction <-> Location links
  defp create_faction_location_link(faction, location, metadata_attrs) do
    changeset_attrs =
      %{
        faction_id: faction.id,
        location_id: location.id
      }
      |> Map.merge(metadata_attrs)

    %FactionLocation{}
    |> FactionLocation.changeset(changeset_attrs)
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
      where: fl.location_id == ^location.id,
      select: %{
        entity: f,
        relationship_type: fl.relationship_type,
        description: fl.description,
        strength: fl.strength,
        is_active: fl.is_active,
        is_current_location: fl.is_current_location,
        metadata: fl.metadata
      }
    )
    |> Repo.all()
  end

  defp get_locations_for_faction(faction) do
    from(l in Location,
      join: fl in FactionLocation,
      on: fl.location_id == l.id,
      where: fl.faction_id == ^faction.id,
      select: %{
        entity: l,
        relationship_type: fl.relationship_type,
        description: fl.description,
        strength: fl.strength,
        is_active: fl.is_active,
        is_current_location: fl.is_current_location,
        metadata: fl.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Character links
  defp create_quest_character_link(quest, character, metadata_attrs) do
    changeset_attrs =
      %{
        quest_id: quest.id,
        character_id: character.id
      }
      |> Map.merge(metadata_attrs)

    %QuestCharacter{}
    |> QuestCharacter.changeset(changeset_attrs)
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
      where: qc.character_id == ^character.id,
      select: %{
        entity: q,
        relationship_type: qc.relationship_type,
        description: qc.description,
        strength: qc.strength,
        is_active: qc.is_active,
        metadata: qc.metadata
      }
    )
    |> Repo.all()
  end

  defp get_characters_for_quest(quest) do
    from(c in Character,
      join: qc in QuestCharacter,
      on: qc.character_id == c.id,
      where: qc.quest_id == ^quest.id,
      select: %{
        entity: c,
        relationship_type: qc.relationship_type,
        description: qc.description,
        strength: qc.strength,
        is_active: qc.is_active,
        metadata: qc.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Faction links
  defp create_quest_faction_link(quest, faction, metadata_attrs) do
    changeset_attrs =
      %{
        quest_id: quest.id,
        faction_id: faction.id
      }
      |> Map.merge(metadata_attrs)

    %QuestFaction{}
    |> QuestFaction.changeset(changeset_attrs)
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
      where: qf.quest_id == ^quest.id,
      select: %{
        entity: f,
        relationship_type: qf.relationship_type,
        description: qf.description,
        strength: qf.strength,
        is_active: qf.is_active,
        metadata: qf.metadata
      }
    )
    |> Repo.all()
  end

  defp get_quests_for_faction(faction) do
    from(q in Quest,
      join: qf in QuestFaction,
      on: qf.quest_id == q.id,
      where: qf.faction_id == ^faction.id,
      select: %{
        entity: q,
        relationship_type: qf.relationship_type,
        description: qf.description,
        strength: qf.strength,
        is_active: qf.is_active,
        metadata: qf.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Location links
  defp create_quest_location_link(quest, location, metadata_attrs) do
    changeset_attrs =
      %{
        quest_id: quest.id,
        location_id: location.id
      }
      |> Map.merge(metadata_attrs)

    %QuestLocation{}
    |> QuestLocation.changeset(changeset_attrs)
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
      where: ql.quest_id == ^quest.id,
      select: %{
        entity: l,
        relationship_type: ql.relationship_type,
        description: ql.description,
        strength: ql.strength,
        is_active: ql.is_active,
        metadata: ql.metadata
      }
    )
    |> Repo.all()
  end

  defp get_quests_for_location(location) do
    from(q in Quest,
      join: ql in QuestLocation,
      on: ql.quest_id == q.id,
      where: ql.location_id == ^location.id,
      select: %{
        entity: q,
        relationship_type: ql.relationship_type,
        description: ql.description,
        strength: ql.strength,
        is_active: ql.is_active,
        metadata: ql.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Note links
  defp create_quest_note_link(quest, note, metadata_attrs) do
    changeset_attrs =
      %{
        quest_id: quest.id,
        note_id: note.id
      }
      |> Map.merge(metadata_attrs)

    %QuestNote{}
    |> QuestNote.changeset(changeset_attrs)
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
      where: qn.quest_id == ^quest.id,
      select: %{
        entity: n,
        relationship_type: qn.relationship_type,
        description: qn.description,
        strength: qn.strength,
        is_active: qn.is_active,
        metadata: qn.metadata
      }
    )
    |> Repo.all()
  end

  defp get_quests_for_note(note) do
    from(q in Quest,
      join: qn in QuestNote,
      on: qn.quest_id == q.id,
      where: qn.note_id == ^note.id,
      select: %{
        entity: q,
        relationship_type: qn.relationship_type,
        description: qn.description,
        strength: qn.strength,
        is_active: qn.is_active,
        metadata: qn.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Character <-> Character links
  defp create_character_character_link(character1, character2, metadata_attrs) do
    changeset_attrs =
      %{
        character_1_id: character1.id,
        character_2_id: character2.id
      }
      |> Map.merge(metadata_attrs)

    %CharacterCharacter{}
    |> CharacterCharacter.changeset(changeset_attrs)
    |> Repo.insert()
  end

  defp remove_character_character_link(character1, character2) do
    # Check both directions since this is bidirectional
    case Repo.get_by(CharacterCharacter,
           character_1_id: character1.id,
           character_2_id: character2.id
         ) do
      nil ->
        case Repo.get_by(CharacterCharacter,
               character_1_id: character2.id,
               character_2_id: character1.id
             ) do
          nil -> {:error, :not_found}
          link -> Repo.delete(link)
        end

      link ->
        Repo.delete(link)
    end
  end

  defp character_character_exists?(character1, character2) do
    Repo.exists?(
      from cc in CharacterCharacter,
        where:
          (cc.character_1_id == ^character1.id and cc.character_2_id == ^character2.id) or
            (cc.character_1_id == ^character2.id and cc.character_2_id == ^character1.id)
    )
  end

  defp get_characters_for_character(character) do
    from(c in Character,
      join: cc in CharacterCharacter,
      on:
        (cc.character_1_id == c.id and cc.character_2_id == ^character.id) or
          (cc.character_2_id == c.id and cc.character_1_id == ^character.id),
      where: c.id != ^character.id,
      select: %{
        entity: c,
        relationship_type: cc.relationship_type,
        description: cc.description,
        strength: cc.strength,
        is_active: cc.is_active,
        metadata: cc.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Faction <-> Faction links
  defp create_faction_faction_link(faction1, faction2, metadata_attrs) do
    changeset_attrs =
      %{
        faction_1_id: faction1.id,
        faction_2_id: faction2.id
      }
      |> Map.merge(metadata_attrs)

    %FactionFaction{}
    |> FactionFaction.changeset(changeset_attrs)
    |> Repo.insert()
  end

  defp remove_faction_faction_link(faction1, faction2) do
    case Repo.get_by(FactionFaction, faction_1_id: faction1.id, faction_2_id: faction2.id) do
      nil ->
        case Repo.get_by(FactionFaction, faction_1_id: faction2.id, faction_2_id: faction1.id) do
          nil -> {:error, :not_found}
          link -> Repo.delete(link)
        end

      link ->
        Repo.delete(link)
    end
  end

  defp faction_faction_exists?(faction1, faction2) do
    Repo.exists?(
      from ff in FactionFaction,
        where:
          (ff.faction_1_id == ^faction1.id and ff.faction_2_id == ^faction2.id) or
            (ff.faction_1_id == ^faction2.id and ff.faction_2_id == ^faction1.id)
    )
  end

  defp get_factions_for_faction(faction) do
    from(f in Faction,
      join: ff in FactionFaction,
      on:
        (ff.faction_1_id == f.id and ff.faction_2_id == ^faction.id) or
          (ff.faction_2_id == f.id and ff.faction_1_id == ^faction.id),
      where: f.id != ^faction.id,
      select: %{
        entity: f,
        relationship_type: ff.relationship_type,
        description: ff.description,
        strength: ff.strength,
        is_active: ff.is_active,
        metadata: ff.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Location <-> Location links
  defp create_location_location_link(location1, location2, metadata_attrs) do
    changeset_attrs =
      %{
        location_1_id: location1.id,
        location_2_id: location2.id
      }
      |> Map.merge(metadata_attrs)

    %LocationLocation{}
    |> LocationLocation.changeset(changeset_attrs)
    |> Repo.insert()
  end

  defp remove_location_location_link(location1, location2) do
    case Repo.get_by(LocationLocation, location_1_id: location1.id, location_2_id: location2.id) do
      nil ->
        case Repo.get_by(LocationLocation,
               location_1_id: location2.id,
               location_2_id: location1.id
             ) do
          nil -> {:error, :not_found}
          link -> Repo.delete(link)
        end

      link ->
        Repo.delete(link)
    end
  end

  defp location_location_exists?(location1, location2) do
    Repo.exists?(
      from ll in LocationLocation,
        where:
          (ll.location_1_id == ^location1.id and ll.location_2_id == ^location2.id) or
            (ll.location_1_id == ^location2.id and ll.location_2_id == ^location1.id)
    )
  end

  defp get_locations_for_location(location) do
    from(l in Location,
      join: ll in LocationLocation,
      on:
        (ll.location_1_id == l.id and ll.location_2_id == ^location.id) or
          (ll.location_2_id == l.id and ll.location_1_id == ^location.id),
      where: l.id != ^location.id,
      select: %{
        entity: l,
        relationship_type: ll.relationship_type,
        description: ll.description,
        strength: ll.strength,
        is_active: ll.is_active,
        metadata: ll.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Quest <-> Quest links
  defp create_quest_quest_link(quest1, quest2, metadata_attrs) do
    changeset_attrs =
      %{
        quest_1_id: quest1.id,
        quest_2_id: quest2.id
      }
      |> Map.merge(metadata_attrs)

    %QuestQuest{}
    |> QuestQuest.changeset(changeset_attrs)
    |> Repo.insert()
  end

  defp remove_quest_quest_link(quest1, quest2) do
    case Repo.get_by(QuestQuest, quest_1_id: quest1.id, quest_2_id: quest2.id) do
      nil ->
        case Repo.get_by(QuestQuest, quest_1_id: quest2.id, quest_2_id: quest1.id) do
          nil -> {:error, :not_found}
          link -> Repo.delete(link)
        end

      link ->
        Repo.delete(link)
    end
  end

  defp quest_quest_exists?(quest1, quest2) do
    Repo.exists?(
      from qq in QuestQuest,
        where:
          (qq.quest_1_id == ^quest1.id and qq.quest_2_id == ^quest2.id) or
            (qq.quest_1_id == ^quest2.id and qq.quest_2_id == ^quest1.id)
    )
  end

  defp get_quests_for_quest(quest) do
    from(q in Quest,
      join: qq in QuestQuest,
      on:
        (qq.quest_1_id == q.id and qq.quest_2_id == ^quest.id) or
          (qq.quest_2_id == q.id and qq.quest_1_id == ^quest.id),
      where: q.id != ^quest.id,
      select: %{
        entity: q,
        relationship_type: qq.relationship_type,
        description: qq.description,
        strength: qq.strength,
        is_active: qq.is_active,
        metadata: qq.metadata
      }
    )
    |> Repo.all()
  end

  # Private functions for Note <-> Note links
  defp create_note_note_link(note1, note2, metadata_attrs) do
    changeset_attrs =
      %{
        note_1_id: note1.id,
        note_2_id: note2.id
      }
      |> Map.merge(metadata_attrs)

    %NoteNote{}
    |> NoteNote.changeset(changeset_attrs)
    |> Repo.insert()
  end

  defp remove_note_note_link(note1, note2) do
    case Repo.get_by(NoteNote, note_1_id: note1.id, note_2_id: note2.id) do
      nil ->
        case Repo.get_by(NoteNote, note_1_id: note2.id, note_2_id: note1.id) do
          nil -> {:error, :not_found}
          link -> Repo.delete(link)
        end

      link ->
        Repo.delete(link)
    end
  end

  defp note_note_exists?(note1, note2) do
    Repo.exists?(
      from nn in NoteNote,
        where:
          (nn.note_1_id == ^note1.id and nn.note_2_id == ^note2.id) or
            (nn.note_1_id == ^note2.id and nn.note_2_id == ^note1.id)
    )
  end

  defp get_notes_for_note(note) do
    from(n in Note,
      join: nn in NoteNote,
      on:
        (nn.note_1_id == n.id and nn.note_2_id == ^note.id) or
          (nn.note_2_id == n.id and nn.note_1_id == ^note.id),
      where: n.id != ^note.id,
      select: %{
        entity: n,
        relationship_type: nn.relationship_type,
        description: nn.description,
        strength: nn.strength,
        is_active: nn.is_active,
        metadata: nn.metadata
      }
    )
    |> Repo.all()
  end

  # Private update functions for Character <-> Note links

  defp update_character_note_link(character, note, metadata_attrs) do
    case Repo.get_by(CharacterNote, character_id: character.id, note_id: note.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> CharacterNote.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Faction <-> Note links

  defp update_faction_note_link(faction, note, metadata_attrs) do
    case Repo.get_by(FactionNote, faction_id: faction.id, note_id: note.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> FactionNote.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Character <-> Faction links

  defp update_character_faction_link(character, faction, metadata_attrs) do
    case Repo.get_by(CharacterFaction, character_id: character.id, faction_id: faction.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> CharacterFaction.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Location <-> Note links

  defp update_location_note_link(location, note, metadata_attrs) do
    case Repo.get_by(LocationNote, location_id: location.id, note_id: note.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> LocationNote.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Character <-> Location links

  defp update_character_location_link(character, location, metadata_attrs) do
    case Repo.get_by(CharacterLocation, character_id: character.id, location_id: location.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> CharacterLocation.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Faction <-> Location links

  defp update_faction_location_link(faction, location, metadata_attrs) do
    case Repo.get_by(FactionLocation, faction_id: faction.id, location_id: location.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> FactionLocation.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Quest <-> Character links

  defp update_quest_character_link(quest, character, metadata_attrs) do
    case Repo.get_by(QuestCharacter, quest_id: quest.id, character_id: character.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> QuestCharacter.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Quest <-> Faction links

  defp update_quest_faction_link(quest, faction, metadata_attrs) do
    case Repo.get_by(QuestFaction, quest_id: quest.id, faction_id: faction.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> QuestFaction.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Quest <-> Location links

  defp update_quest_location_link(quest, location, metadata_attrs) do
    case Repo.get_by(QuestLocation, quest_id: quest.id, location_id: location.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> QuestLocation.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Quest <-> Note links

  defp update_quest_note_link(quest, note, metadata_attrs) do
    case Repo.get_by(QuestNote, quest_id: quest.id, note_id: note.id) do
      nil ->
        {:error, :not_found}

      link ->
        link
        |> QuestNote.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Character <-> Character links

  defp update_character_character_link(character1, character2, metadata_attrs) do
    # Check both directions since this is bidirectional
    case Repo.get_by(CharacterCharacter,
           character_1_id: character1.id,
           character_2_id: character2.id
         ) do
      nil ->
        case Repo.get_by(CharacterCharacter,
               character_1_id: character2.id,
               character_2_id: character1.id
             ) do
          nil ->
            {:error, :not_found}

          link ->
            link
            |> CharacterCharacter.changeset(metadata_attrs)
            |> Repo.update()
        end

      link ->
        link
        |> CharacterCharacter.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Faction <-> Faction links

  defp update_faction_faction_link(faction1, faction2, metadata_attrs) do
    case Repo.get_by(FactionFaction, faction_1_id: faction1.id, faction_2_id: faction2.id) do
      nil ->
        case Repo.get_by(FactionFaction, faction_1_id: faction2.id, faction_2_id: faction1.id) do
          nil ->
            {:error, :not_found}

          link ->
            link
            |> FactionFaction.changeset(metadata_attrs)
            |> Repo.update()
        end

      link ->
        link
        |> FactionFaction.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Location <-> Location links

  defp update_location_location_link(location1, location2, metadata_attrs) do
    case Repo.get_by(LocationLocation, location_1_id: location1.id, location_2_id: location2.id) do
      nil ->
        case Repo.get_by(LocationLocation,
               location_1_id: location2.id,
               location_2_id: location1.id
             ) do
          nil ->
            {:error, :not_found}

          link ->
            link
            |> LocationLocation.changeset(metadata_attrs)
            |> Repo.update()
        end

      link ->
        link
        |> LocationLocation.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Quest <-> Quest links

  defp update_quest_quest_link(quest1, quest2, metadata_attrs) do
    case Repo.get_by(QuestQuest, quest_1_id: quest1.id, quest_2_id: quest2.id) do
      nil ->
        case Repo.get_by(QuestQuest, quest_1_id: quest2.id, quest_2_id: quest1.id) do
          nil ->
            {:error, :not_found}

          link ->
            link
            |> QuestQuest.changeset(metadata_attrs)
            |> Repo.update()
        end

      link ->
        link
        |> QuestQuest.changeset(metadata_attrs)
        |> Repo.update()
    end
  end

  # Private update functions for Note <-> Note links

  defp update_note_note_link(note1, note2, metadata_attrs) do
    case Repo.get_by(NoteNote, note_1_id: note1.id, note_2_id: note2.id) do
      nil ->
        case Repo.get_by(NoteNote, note_1_id: note2.id, note_2_id: note1.id) do
          nil ->
            {:error, :not_found}

          link ->
            link
            |> NoteNote.changeset(metadata_attrs)
            |> Repo.update()
        end

      link ->
        link
        |> NoteNote.changeset(metadata_attrs)
        |> Repo.update()
    end
  end
end
