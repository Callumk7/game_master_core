defmodule GameMasterCore.Repo.Migrations.FixJoinTableForeignKeyConstraints do
  use Ecto.Migration

  def up do
    # Drop existing foreign key constraints and recreate with cascade deletion
    # This ensures that when main entities are deleted, their join table records are also deleted

    # Fix character_factions table
    drop_if_exists constraint(:character_factions, "character_factions_character_id_fkey")
    drop_if_exists constraint(:character_factions, "character_factions_faction_id_fkey")

    alter table(:character_factions) do
      modify :character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :delete_all)
    end

    # Fix character_notes table
    drop_if_exists constraint(:character_notes, "character_notes_character_id_fkey")
    drop_if_exists constraint(:character_notes, "character_notes_note_id_fkey")

    alter table(:character_notes) do
      modify :character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :delete_all)
    end

    # Fix faction_notes table
    drop_if_exists constraint(:faction_notes, "faction_notes_faction_id_fkey")
    drop_if_exists constraint(:faction_notes, "faction_notes_note_id_fkey")

    alter table(:faction_notes) do
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :delete_all)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :delete_all)
    end

    # Fix location_notes table
    drop_if_exists constraint(:location_notes, "location_notes_location_id_fkey")
    drop_if_exists constraint(:location_notes, "location_notes_note_id_fkey")

    alter table(:location_notes) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :delete_all)
    end

    # Fix character_locations table
    drop_if_exists constraint(:character_locations, "character_locations_location_id_fkey")
    drop_if_exists constraint(:character_locations, "character_locations_character_id_fkey")

    alter table(:character_locations) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
      modify :character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
    end

    # Fix faction_locations table
    drop_if_exists constraint(:faction_locations, "faction_locations_location_id_fkey")
    drop_if_exists constraint(:faction_locations, "faction_locations_faction_id_fkey")

    alter table(:faction_locations) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :delete_all)
    end

    # Fix quests_characters table
    drop_if_exists constraint(:quests_characters, "quests_characters_quest_id_fkey")
    drop_if_exists constraint(:quests_characters, "quests_characters_character_id_fkey")

    alter table(:quests_characters) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :delete_all)
      modify :character_id, references(:characters, type: :binary_id, on_delete: :delete_all)
    end

    # Fix quests_factions table
    drop_if_exists constraint(:quests_factions, "quests_factions_quest_id_fkey")
    drop_if_exists constraint(:quests_factions, "quests_factions_faction_id_fkey")

    alter table(:quests_factions) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :delete_all)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :delete_all)
    end

    # Fix quests_notes table
    drop_if_exists constraint(:quests_notes, "quests_notes_quest_id_fkey")
    drop_if_exists constraint(:quests_notes, "quests_notes_note_id_fkey")

    alter table(:quests_notes) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :delete_all)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :delete_all)
    end

    # Fix quests_locations table
    drop_if_exists constraint(:quests_locations, "quests_locations_quest_id_fkey")
    drop_if_exists constraint(:quests_locations, "quests_locations_location_id_fkey")

    alter table(:quests_locations) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :delete_all)
      modify :location_id, references(:locations, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    # Reverse the changes by setting constraints back to :nothing
    # Note: This should generally not be used in production as it could cause data integrity issues

    # Revert character_factions table
    alter table(:character_factions) do
      modify :character_id, references(:characters, type: :binary_id, on_delete: :nothing)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)
    end

    # Revert character_notes table
    alter table(:character_notes) do
      modify :character_id, references(:characters, type: :binary_id, on_delete: :nothing)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :nothing)
    end

    # Revert faction_notes table
    alter table(:faction_notes) do
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :nothing)
    end

    # Revert location_notes table
    alter table(:location_notes) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :nothing)
    end

    # Revert character_locations table
    alter table(:character_locations) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      modify :character_id, references(:characters, type: :binary_id, on_delete: :nothing)
    end

    # Revert faction_locations table
    alter table(:faction_locations) do
      modify :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)
    end

    # Revert quests_characters table
    alter table(:quests_characters) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :nothing)
      modify :character_id, references(:characters, type: :binary_id, on_delete: :nothing)
    end

    # Revert quests_factions table
    alter table(:quests_factions) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :nothing)
      modify :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)
    end

    # Revert quests_notes table
    alter table(:quests_notes) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :nothing)
      modify :note_id, references(:notes, type: :binary_id, on_delete: :nothing)
    end

    # Revert quests_locations table
    alter table(:quests_locations) do
      modify :quest_id, references(:quests, type: :binary_id, on_delete: :nothing)
      modify :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
    end
  end
end
