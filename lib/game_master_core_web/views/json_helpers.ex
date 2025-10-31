defmodule GameMasterCoreWeb.JSONHelpers do
  @moduledoc """
  Shared JSON data formatting functions for API responses.

  This module provides consistent data transformation functions
  that can be used across different JSON views.
  """

  alias GameMasterCore.Notes.Note
  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Games.Game

  @doc """
  Formats a note for JSON response.
  """
  def note_data(%Note{} = note) do
    %{
      id: note.id,
      game_id: note.game_id,
      name: note.name,
      content: note.content,
      content_plain_text: note.content_plain_text,
      tags: note.tags,
      pinned: note.pinned,
      visibility: note.visibility,
      created_at: note.inserted_at,
      updated_at: note.updated_at
    }
  end

  @doc """
  Formats a character for JSON response (full data).
  """
  def character_data(%Character{} = character) do
    %{
      id: character.id,
      game_id: character.game_id,
      name: character.name,
      content: character.content,
      content_plain_text: character.content_plain_text,
      class: character.class,
      level: character.level,
      tags: character.tags,
      pinned: character.pinned,
      visibility: character.visibility,
      race: character.race,
      alive: character.alive,
      created_at: character.inserted_at,
      updated_at: character.updated_at
    }
  end

  @doc """
  Formats a faction for JSON response.
  """
  def faction_data(%Faction{} = faction) do
    %{
      id: faction.id,
      game_id: faction.game_id,
      name: faction.name,
      content: faction.content,
      content_plain_text: faction.content_plain_text,
      tags: faction.tags,
      pinned: faction.pinned,
      visibility: faction.visibility,
      created_at: faction.inserted_at,
      updated_at: faction.updated_at
    }
  end

  @doc """
  Formats a game for JSON response.
  """
  def game_data(%Game{} = game) do
    %{
      id: game.id,
      name: game.name,
      content: game.content,
      content_plain_text: game.content_plain_text,
      setting: game.setting,
      created_at: game.inserted_at,
      updated_at: game.updated_at
    }
  end

  @doc """
  Formats a location for JSON response.
  """
  def location_data(%Location{} = location) do
    %{
      id: location.id,
      game_id: location.game_id,
      name: location.name,
      content: location.content,
      content_plain_text: location.content_plain_text,
      type: location.type,
      parent_id: location.parent_id,
      tags: location.tags,
      pinned: location.pinned,
      visibility: location.visibility,
      created_at: location.inserted_at,
      updated_at: location.updated_at
    }
  end

  @doc """
  Formats a quest for JSON response.
  """
  def quest_data(%Quest{} = quest) do
    %{
      id: quest.id,
      game_id: quest.game_id,
      name: quest.name,
      content: quest.content,
      content_plain_text: quest.content_plain_text,
      tags: quest.tags,
      parent_id: quest.parent_id,
      pinned: quest.pinned,
      visibility: quest.visibility,
      status: quest.status,
      created_at: quest.inserted_at,
      updated_at: quest.updated_at
    }
  end

  def character_data_with_metadata(%{
        entity: character,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        metadata: metadata
      }) do
    character_data(character)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      metadata: metadata
    })
  end

  def character_data_with_metadata_with_faction(%{
        entity: character,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        is_primary: is_primary,
        faction_role: faction_role,
        metadata: metadata
      }) do
    character_data(character)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      is_primary: is_primary,
      faction_role: faction_role,
      metadata: metadata
    })
  end

  def character_data_with_metadata_with_location(%{
        entity: character,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        is_current_location: is_current_location,
        metadata: metadata
      }) do
    character_data(character)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      is_current_location: is_current_location,
      metadata: metadata
    })
  end

  def faction_data_with_metadata(%{
        entity: faction,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        metadata: metadata
      }) do
    faction_data(faction)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      metadata: metadata
    })
  end

  def faction_data_with_metadata_with_faction(%{
        entity: faction,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        is_primary: is_primary,
        faction_role: faction_role,
        metadata: metadata
      }) do
    faction_data(faction)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      is_primary: is_primary,
      faction_role: faction_role,
      metadata: metadata
    })
  end

  def faction_data_with_metadata_with_location(%{
        entity: faction,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        is_current_location: is_current_location,
        metadata: metadata
      }) do
    faction_data(faction)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      is_current_location: is_current_location,
      metadata: metadata
    })
  end

  def location_data_with_metadata(%{
        entity: location,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        metadata: metadata
      }) do
    location_data(location)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      metadata: metadata
    })
  end

  def location_data_with_metadata_with_current_location(%{
        entity: location,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        is_current_location: is_current_location,
        metadata: metadata
      }) do
    location_data(location)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      is_current_location: is_current_location,
      metadata: metadata
    })
  end

  def quest_data_with_metadata(%{
        entity: quest,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        metadata: metadata
      }) do
    quest_data(quest)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      metadata: metadata
    })
  end

  def note_data_with_metadata(%{
        entity: note,
        relationship_type: relationship_type,
        description: description,
        strength: strength,
        is_active: is_active,
        metadata: metadata
      }) do
    note_data(note)
    |> Map.merge(%{
      relationship_type: relationship_type,
      description_meta: description,
      strength: strength,
      is_active: is_active,
      metadata: metadata
    })
  end
end
