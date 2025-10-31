defmodule GameMasterCore.Repo.Migrations.CreateEntityShares do
  use Ecto.Migration

  def up do
    create table(:entity_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Polymorphic entity reference
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false

      # User being granted access
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      # Permission level: "editor", "viewer", "blocked"
      add :permission, :string, null: false

      # Who granted this permission (for audit trail)
      add :shared_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # Indexes for performance
    create index(:entity_shares, [:entity_type, :entity_id])
    create index(:entity_shares, [:user_id])
    create unique_index(:entity_shares, [:entity_type, :entity_id, :user_id])

    # Create trigger function to cascade delete shares when entities are deleted
    execute """
    CREATE OR REPLACE FUNCTION delete_entity_shares()
    RETURNS TRIGGER AS $$
    BEGIN
      DELETE FROM entity_shares
      WHERE entity_type = TG_ARGV[0]
        AND entity_id = OLD.id;
      RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create triggers on each entity table
    execute """
    CREATE TRIGGER delete_character_shares
    AFTER DELETE ON characters
    FOR EACH ROW
    EXECUTE FUNCTION delete_entity_shares('character');
    """

    execute """
    CREATE TRIGGER delete_faction_shares
    AFTER DELETE ON factions
    FOR EACH ROW
    EXECUTE FUNCTION delete_entity_shares('faction');
    """

    execute """
    CREATE TRIGGER delete_location_shares
    AFTER DELETE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION delete_entity_shares('location');
    """

    execute """
    CREATE TRIGGER delete_quest_shares
    AFTER DELETE ON quests
    FOR EACH ROW
    EXECUTE FUNCTION delete_entity_shares('quest');
    """

    execute """
    CREATE TRIGGER delete_note_shares
    AFTER DELETE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION delete_entity_shares('note');
    """
  end

  def down do
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
  end
end
