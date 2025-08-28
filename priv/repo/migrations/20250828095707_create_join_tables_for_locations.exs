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

    create table(:location_characters) do
      add :location_id, references(:locations, on_delete: :nothing)
      add :character_id, references(:characters, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:location_characters, [:location_id])
    create index(:location_characters, [:character_id])

    create unique_index(:location_characters, [:location_id, :character_id])

    create table(:location_factions) do
      add :location_id, references(:locations, on_delete: :nothing)
      add :faction_id, references(:factions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:location_factions, [:location_id])
    create index(:location_factions, [:faction_id])

    create unique_index(:location_factions, [:location_id, :faction_id])
  end
end
