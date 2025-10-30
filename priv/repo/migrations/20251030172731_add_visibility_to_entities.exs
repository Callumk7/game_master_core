defmodule GameMasterCore.Repo.Migrations.AddVisibilityToEntities do
  use Ecto.Migration

  def change do
    # Add visibility field to all entity tables
    alter table(:characters) do
      add :visibility, :string, default: "private", null: false
    end

    alter table(:factions) do
      add :visibility, :string, default: "private", null: false
    end

    alter table(:locations) do
      add :visibility, :string, default: "private", null: false
    end

    alter table(:quests) do
      add :visibility, :string, default: "private", null: false
    end

    alter table(:notes) do
      add :visibility, :string, default: "private", null: false
    end

    # Add indexes for efficient visibility filtering
    create index(:characters, [:visibility])
    create index(:factions, [:visibility])
    create index(:locations, [:visibility])
    create index(:quests, [:visibility])
    create index(:notes, [:visibility])
  end
end
