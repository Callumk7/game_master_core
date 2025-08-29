defmodule GameMasterCore.Repo.Migrations.CreateQuests do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :name, :string
      add :content, :string
      add :game_id, references(:games, type: :id, on_delete: :delete_all)
      add :user_id, references(:users, type: :id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:quests, [:game_id])

    create table(:quests_characters) do
      add :quest_id, references(:quests, on_delete: :nothing)
      add :character_id, references(:characters, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:quests_characters, [:quest_id])
    create index(:quests_characters, [:character_id])

    create unique_index(:quests_characters, [:quest_id, :character_id])

    create table(:quests_factions) do
      add :quest_id, references(:quests, on_delete: :nothing)
      add :faction_id, references(:factions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:quests_factions, [:quest_id])
    create index(:quests_factions, [:faction_id])

    create unique_index(:quests_factions, [:quest_id, :faction_id])

    create table(:quests_notes) do
      add :quest_id, references(:quests, on_delete: :nothing)
      add :note_id, references(:notes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:quests_notes, [:quest_id])
    create index(:quests_notes, [:note_id])

    create unique_index(:quests_notes, [:quest_id, :note_id])

    create table(:quests_locations) do
      add :quest_id, references(:quests, on_delete: :nothing)
      add :location_id, references(:locations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:quests_locations, [:quest_id])
    create index(:quests_locations, [:location_id])

    create unique_index(:quests_locations, [:quest_id, :location_id])
  end
end
