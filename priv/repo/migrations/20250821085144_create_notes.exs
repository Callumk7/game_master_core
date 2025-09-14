defmodule GameMasterCore.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :content, :string
      add :game_id, references(:games, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:notes, [:user_id])

    create index(:notes, [:game_id])
  end
end
