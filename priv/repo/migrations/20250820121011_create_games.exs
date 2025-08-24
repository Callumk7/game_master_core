defmodule GameMasterCore.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
      add :description, :string
      add :setting, :string
      add :owner_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:owner_id])
  end
end
