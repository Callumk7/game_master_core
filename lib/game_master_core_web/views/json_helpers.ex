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
  alias GameMasterCore.Images
  alias GameMasterCore.Images.Image

  @doc """
  Formats a note for JSON response.
  """
  def note_data(%Note{} = note) do
    %{
      id: note.id,
      name: note.name,
      content: note.content,
      content_plain_text: note.content_plain_text,
      tags: note.tags,
      parent_id: note.parent_id,
      parent_type: note.parent_type,
      pinned: note.pinned,
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
      name: character.name,
      content: character.content,
      content_plain_text: character.content_plain_text,
      class: character.class,
      level: character.level,
      image_url: character.image_url,
      tags: character.tags,
      member_of_faction_id: character.member_of_faction_id,
      faction_role: character.faction_role,
      pinned: character.pinned,
      race: character.race,
      alive: character.alive,
      created_at: character.inserted_at,
      updated_at: character.updated_at
    }
  end

  @doc """
  Enhanced character data with image information.
  """
  def character_data_with_images(%Character{} = character, scope) do
    character_data(character)
    |> add_image_info(scope, "character", character.id)
  end

  @doc """
  Formats a faction for JSON response.
  """
  def faction_data(%Faction{} = faction) do
    %{
      id: faction.id,
      name: faction.name,
      content: faction.content,
      content_plain_text: faction.content_plain_text,
      tags: faction.tags,
      pinned: faction.pinned,
      created_at: faction.inserted_at,
      updated_at: faction.updated_at
    }
  end

  @doc """
  Enhanced faction data with image information.
  """
  def faction_data_with_images(%Faction{} = faction, scope) do
    faction_data(faction)
    |> add_image_info(scope, "faction", faction.id)
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
      name: location.name,
      content: location.content,
      content_plain_text: location.content_plain_text,
      type: location.type,
      has_parent: location.parent_id != nil,
      tags: location.tags,
      pinned: location.pinned,
      created_at: location.inserted_at,
      updated_at: location.updated_at
    }
  end

  @doc """
  Enhanced location data with image information.
  """
  def location_data_with_images(%Location{} = location, scope) do
    location_data(location)
    |> add_image_info(scope, "location", location.id)
  end

  @doc """
  Formats a quest for JSON response.
  """
  def quest_data(%Quest{} = quest) do
    %{
      id: quest.id,
      name: quest.name,
      content: quest.content,
      content_plain_text: quest.content_plain_text,
      tags: quest.tags,
      parent_id: quest.parent_id,
      pinned: quest.pinned,
      status: quest.status,
      created_at: quest.inserted_at,
      updated_at: quest.updated_at
    }
  end

  @doc """
  Enhanced quest data with image information.
  """
  def quest_data_with_images(%Quest{} = quest, scope) do
    quest_data(quest)
    |> add_image_info(scope, "quest", quest.id)
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

  # Private helper functions for image integration

  defp add_image_info(entity_data, scope, entity_type, entity_id) do
    # Get primary image
    primary_image =
      case Images.get_primary_image(scope, entity_type, entity_id) do
        {:ok, image} -> format_image_data(image)
        {:error, :not_found} -> nil
      end

    # Get image statistics
    stats = Images.get_image_stats(scope, entity_type, entity_id)

    entity_data
    |> Map.put(:primary_image, primary_image)
    |> Map.put(:image_stats, %{
      total_count: stats.total_count,
      total_size: stats.total_size,
      has_primary: stats.has_primary
    })
  end

  defp format_image_data(%Image{} = image) do
    %{
      id: image.id,
      filename: image.filename,
      file_url: image.file_url,
      alt_text: image.alt_text,
      file_size: image.file_size,
      content_type: image.content_type
    }
  end
end
