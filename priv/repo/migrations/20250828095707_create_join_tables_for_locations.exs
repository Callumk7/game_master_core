defmodule GameMasterCore.Repo.Migrations.CreateJoinTablesForLocations do
  use Ecto.Migration

  def change do
    create table(:location_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      add :note_id, references(:notes, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:location_notes, [:location_id])
    create index(:location_notes, [:note_id])

    create unique_index(:location_notes, [:location_id, :note_id])

    create table(:character_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      add :character_id, references(:characters, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:character_locations, [:location_id])
    create index(:character_locations, [:character_id])

    create unique_index(:character_locations, [:location_id, :character_id])

    create table(:faction_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :location_id, references(:locations, type: :binary_id, on_delete: :nothing)
      add :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:faction_locations, [:location_id])
    create index(:faction_locations, [:faction_id])

    create unique_index(:faction_locations, [:location_id, :faction_id])
  end
end
