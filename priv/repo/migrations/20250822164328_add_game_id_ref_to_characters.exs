defmodule GameMasterCore.Repo.Migrations.AddGameIdRefToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :game_id, references(:games, type: :binary_id, on_delete: :nothing)
    end

    create index(:characters, [:game_id])
  end
end
