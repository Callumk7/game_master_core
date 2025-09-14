defmodule GameMasterCore.Repo.Migrations.CreateGameMembersTable do
  use Ecto.Migration

  def change do
    create table(:game_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :role, :string, default: "member"

      timestamps(type: :utc_datetime)
    end

    create index(:game_members, [:game_id])
    create index(:game_members, [:user_id])
    create unique_index(:game_members, [:game_id, :user_id])
  end
end
