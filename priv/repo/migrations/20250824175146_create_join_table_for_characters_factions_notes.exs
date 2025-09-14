defmodule GameMasterCore.Repo.Migrations.CreateJoinTableForCharactersFactionsNotes do
  use Ecto.Migration

  def change do
    create table(:faction_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)
      add :note_id, references(:notes, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:faction_notes, [:faction_id])
    create index(:faction_notes, [:note_id])

    create unique_index(:faction_notes, [:faction_id, :note_id])

    create table(:character_factions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :character_id, references(:characters, type: :binary_id, on_delete: :nothing)
      add :faction_id, references(:factions, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:character_factions, [:character_id])
    create index(:character_factions, [:faction_id])

    create unique_index(:character_factions, [:character_id, :faction_id])
  end
end
