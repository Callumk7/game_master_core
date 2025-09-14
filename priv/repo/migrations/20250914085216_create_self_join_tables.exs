defmodule GameMasterCore.Repo.Migrations.CreateSelfJoinTables do
  use Ecto.Migration

  def change do
    create table(:character_characters) do
      add :character_1_id, references(:characters, on_delete: :delete_all), null: false
      add :character_2_id, references(:characters, on_delete: :delete_all), null: false
      add :relationship_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:character_characters, [:character_1_id])
    create index(:character_characters, [:character_2_id])
    create unique_index(:character_characters, [:character_1_id, :character_2_id])

    create constraint(:character_characters, :no_self_link,
             check: "character_1_id != character_2_id"
           )

    create table(:faction_factions) do
      add :faction_1_id, references(:factions, on_delete: :delete_all), null: false
      add :faction_2_id, references(:factions, on_delete: :delete_all), null: false
      add :relationship_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:faction_factions, [:faction_1_id])
    create index(:faction_factions, [:faction_2_id])
    create unique_index(:faction_factions, [:faction_1_id, :faction_2_id])

    create constraint(:faction_factions, :no_self_link, check: "faction_1_id != faction_2_id")

    create table(:location_locations) do
      add :location_1_id, references(:locations, on_delete: :delete_all), null: false
      add :location_2_id, references(:locations, on_delete: :delete_all), null: false
      add :relationship_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:location_locations, [:location_1_id])
    create index(:location_locations, [:location_2_id])
    create unique_index(:location_locations, [:location_1_id, :location_2_id])

    create constraint(:location_locations, :no_self_link, check: "location_1_id != location_2_id")

    create table(:quest_quests) do
      add :quest_1_id, references(:quests, on_delete: :delete_all), null: false
      add :quest_2_id, references(:quests, on_delete: :delete_all), null: false
      add :relationship_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:quest_quests, [:quest_1_id])
    create index(:quest_quests, [:quest_2_id])
    create unique_index(:quest_quests, [:quest_1_id, :quest_2_id])

    create constraint(:quest_quests, :no_self_link, check: "quest_1_id != quest_2_id")

    create table(:note_notes) do
      add :note_1_id, references(:notes, on_delete: :delete_all), null: false
      add :note_2_id, references(:notes, on_delete: :delete_all), null: false
      add :relationship_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:note_notes, [:note_1_id])
    create index(:note_notes, [:note_2_id])
    create unique_index(:note_notes, [:note_1_id, :note_2_id])

    create constraint(:note_notes, :no_self_link, check: "note_1_id != note_2_id")
  end
end
