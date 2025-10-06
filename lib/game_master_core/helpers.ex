defmodule GameMasterCore.Helpers do
  alias GameMasterCore.Locations
  alias GameMasterCore.Characters
  alias GameMasterCore.Factions
  alias GameMasterCore.Quests
  alias GameMasterCore.Notes

  def get_scoped_character(scope, character_id) do
    try do
      character = Characters.get_character_for_game!(scope, character_id)
      {:ok, character}
    rescue
      Ecto.NoResultsError -> {:error, :character_not_found}
    end
  end

  def get_scoped_note(scope, note_id) do
    try do
      note = Notes.get_note_for_game!(scope, note_id)
      {:ok, note}
    rescue
      Ecto.NoResultsError -> {:error, :note_not_found}
    end
  end

  def get_scoped_faction(scope, faction_id) do
    try do
      faction = Factions.get_faction_for_game!(scope, faction_id)
      {:ok, faction}
    rescue
      Ecto.NoResultsError -> {:error, :faction_not_found}
    end
  end

  def get_scoped_location(scope, location_id) do
    try do
      location = Locations.get_location_for_game!(scope, location_id)
      {:ok, location}
    rescue
      Ecto.NoResultsError -> {:error, :location_not_found}
    end
  end

  def get_scoped_quest(scope, quest_id) do
    try do
      quest = Quests.get_quest_for_game!(scope, quest_id)
      {:ok, quest}
    rescue
      Ecto.NoResultsError -> {:error, :quest_not_found}
    end
  end
end
