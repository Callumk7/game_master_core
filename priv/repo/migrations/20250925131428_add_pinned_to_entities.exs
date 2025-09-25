defmodule GameMasterCore.Repo.Migrations.AddPinnedToEntities do
  use Ecto.Migration

  def change do
    # Add pinned column to all entity tables
    alter table(:characters) do
      add :pinned, :boolean, default: false, null: false
    end

    alter table(:notes) do
      add :pinned, :boolean, default: false, null: false
    end

    alter table(:factions) do
      add :pinned, :boolean, default: false, null: false
    end

    alter table(:locations) do
      add :pinned, :boolean, default: false, null: false
    end

    alter table(:quests) do
      add :pinned, :boolean, default: false, null: false
    end

    # Add indexes for efficient pinned entity queries
    create index(:characters, [:game_id, :pinned])
    create index(:notes, [:game_id, :pinned])
    create index(:factions, [:game_id, :pinned])
    create index(:locations, [:game_id, :pinned])
    create index(:quests, [:game_id, :pinned])
  end
end
