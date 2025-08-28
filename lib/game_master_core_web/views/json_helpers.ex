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
  alias GameMasterCore.Games.Game

  @doc """
  Formats a note for JSON response.
  """
  def note_data(%Note{} = note) do
    %{
      id: note.id,
      name: note.name,
      content: note.content
    }
  end

  @doc """
  Formats a character for JSON response (full data).
  """
  def character_data(%Character{} = character) do
    %{
      id: character.id,
      name: character.name,
      description: character.description,
      class: character.class,
      level: character.level,
      image_url: character.image_url
    }
  end

  @doc """
  Formats a character for JSON response (summary data for links).
  """
  def character_summary_data(%Character{} = character) do
    %{
      id: character.id,
      name: character.name,
      level: character.level,
      class: character.class
    }
  end

  @doc """
  Formats a faction for JSON response.
  """
  def faction_data(%Faction{} = faction) do
    %{
      id: faction.id,
      name: faction.name,
      description: faction.description
    }
  end

  @doc """
  Formats a game for JSON response.
  """
  def game_data(%Game{} = game) do
    %{
      id: game.id,
      name: game.name,
      description: game.description,
      setting: game.setting
    }
  end

  @doc """
  Formats a location for JSON response.
  """
  def location_data(%Location{} = location) do
    %{
      id: location.id,
      name: location.name,
      description: location.description,
      type: location.type,
      has_parent: location.parent_id != nil
    }
  end
end

