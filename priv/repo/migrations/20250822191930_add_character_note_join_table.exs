defmodule GameMasterCore.Repo.Migrations.AddCharacterNoteJoinTable do
  use Ecto.Migration

  def change do
    create table(:character_notes) do
      add :character_id, references(:characters, on_delete: :nothing)
      add :note_id, references(:notes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:character_notes, [:character_id])
    create index(:character_notes, [:note_id])

    create unique_index(:character_notes, [:character_id, :note_id])
  end
end
