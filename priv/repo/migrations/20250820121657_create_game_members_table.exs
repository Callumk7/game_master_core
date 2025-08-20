defmodule GameMasterCore.Repo.Migrations.CreateGameMembersTable do
  use Ecto.Migration

  def change do
    create table(:game_members) do
      add :game_id, references(:games, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :role, :string, default: "member"

      timestamps(type: :utc_datetime)
    end

    create index(:game_members, [:game_id])
    create index(:game_members, [:user_id])
    create unique_index(:game_members, [:game_id, :user_id])
  end
end
