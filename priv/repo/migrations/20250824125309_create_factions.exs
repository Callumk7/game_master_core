defmodule GameMasterCore.Repo.Migrations.CreateFactions do
  use Ecto.Migration

  def change do
    create table(:factions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :content, :string
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:factions, [:game_id])
  end
end
