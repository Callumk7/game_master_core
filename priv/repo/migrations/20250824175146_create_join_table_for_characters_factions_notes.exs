defmodule GameMasterCore.Repo.Migrations.CreateJoinTableForCharactersFactionsNotes do
  use Ecto.Migration

  def change do
    create table(:faction_notes) do
      add :faction_id, references(:factions, on_delete: :nothing)
      add :note_id, references(:notes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:faction_notes, [:faction_id])
    create index(:faction_notes, [:note_id])

    create unique_index(:faction_notes, [:faction_id, :note_id])

    create table(:character_factions) do
      add :character_id, references(:characters, on_delete: :nothing)
      add :faction_id, references(:factions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:character_factions, [:character_id])
    create index(:character_factions, [:faction_id])

    create unique_index(:character_factions, [:character_id, :faction_id])
  end
end
