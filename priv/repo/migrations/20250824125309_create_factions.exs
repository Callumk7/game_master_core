defmodule GameMasterCore.Repo.Migrations.CreateFactions do
  use Ecto.Migration

  def change do
    create table(:factions) do
      add :name, :string
      add :description, :string
      add :game_id, references(:games, type: :id, on_delete: :delete_all)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:factions, [:game_id])
  end
end
