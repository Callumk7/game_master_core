defmodule GameMasterCore.Repo.Migrations.CreateJoinTablesForLocations do
  use Ecto.Migration

  def change do
    create table(:location_notes) do
      add :location_id, references(:locations, on_delete: :nothing)
      add :note_id, references(:notes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:location_notes, [:location_id])
    create index(:location_notes, [:note_id])

    create unique_index(:location_notes, [:location_id, :note_id])

    create table(:character_locations) do
      add :location_id, references(:locations, on_delete: :nothing)
      add :character_id, references(:characters, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:character_locations, [:location_id])
    create index(:character_locations, [:character_id])

    create unique_index(:character_locations, [:location_id, :character_id])

    create table(:faction_locations) do
      add :location_id, references(:locations, on_delete: :nothing)
      add :faction_id, references(:factions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:faction_locations, [:location_id])
    create index(:faction_locations, [:faction_id])

    create unique_index(:faction_locations, [:location_id, :faction_id])
  end
end
