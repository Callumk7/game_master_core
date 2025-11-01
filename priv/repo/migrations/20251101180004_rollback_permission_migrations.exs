defmodule GameMasterCore.Repo.Migrations.RollbackPermissionMigrations do
  use Ecto.Migration

  def up do
    # --- 1. Undo CreateEntityShares ---
    # Drop triggers
    execute "DROP TRIGGER IF EXISTS delete_character_shares ON characters;"
    execute "DROP TRIGGER IF EXISTS delete_faction_shares ON factions;"
    execute "DROP TRIGGER IF EXISTS delete_location_shares ON locations;"
    execute "DROP TRIGGER IF EXISTS delete_quest_shares ON quests;"
    execute "DROP TRIGGER IF EXISTS delete_note_shares ON notes;"

    # Drop trigger function
    execute "DROP FUNCTION IF EXISTS delete_entity_shares();"

    # Drop indexes
    drop unique_index(:entity_shares, [:entity_type, :entity_id, :user_id])
    drop index(:entity_shares, [:user_id])
    drop index(:entity_shares, [:entity_type, :entity_id])

    # Drop table
    drop table(:entity_shares)

    # --- 2. Undo AddVisibilityToEntities ---
    # Drop indexes
    drop index(:characters, [:visibility])
    drop index(:factions, [:visibility])
    drop index(:locations, [:visibility])
    drop index(:quests, [:visibility])
    drop index(:notes, [:visibility])

    # Remove visibility columns
    alter table(:characters) do
      remove :visibility
    end

    alter table(:factions) do
      remove :visibility
    end

    alter table(:locations) do
      remove :visibility
    end

    alter table(:quests) do
      remove :visibility
    end

    alter table(:notes) do
      remove :visibility
    end

    # --- 3. Undo UpdateGameMembershipRoles ---
    # Reverse the data migration
    execute "UPDATE game_members SET role = 'owner' WHERE role = 'admin'"
    execute "UPDATE game_members SET role = 'member' WHERE role = 'game_master'"
  end

  def down do
    # This migration is one-way.
    raise "This migration to roll back features is not reversible."
  end
end
