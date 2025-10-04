defmodule GameMasterCore.Repo.Migrations.CreateObjectives do
  use Ecto.Migration

  def change do
    create table(:objectives, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :string, null: false
      add :complete, :boolean, default: false, null: false
      add :quest_id, references(:quests, type: :binary_id, on_delete: :delete_all), null: false
      add :note_link_id, references(:notes, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:objectives, [:quest_id])
    create index(:objectives, [:note_link_id])
    create index(:objectives, [:complete])
  end
end
