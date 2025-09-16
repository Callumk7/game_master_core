defmodule GameMasterCore.Repo.Migrations.AddTagsToEntities do
  use Ecto.Migration

  def change do
    # Add tags array field to all entity tables
    alter table(:characters) do
      add :tags, {:array, :string}, default: []
    end

    alter table(:factions) do
      add :tags, {:array, :string}, default: []
    end

    alter table(:locations) do
      add :tags, {:array, :string}, default: []
    end

    alter table(:quests) do
      add :tags, {:array, :string}, default: []
    end

    alter table(:notes) do
      add :tags, {:array, :string}, default: []
    end

    # Add GIN indexes for efficient tag querying
    create index(:characters, [:tags], using: :gin)
    create index(:factions, [:tags], using: :gin)
    create index(:locations, [:tags], using: :gin)
    create index(:quests, [:tags], using: :gin)
    create index(:notes, [:tags], using: :gin)
  end
end
