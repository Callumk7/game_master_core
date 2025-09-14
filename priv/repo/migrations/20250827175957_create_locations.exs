defmodule GameMasterCore.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :type, :string
      add :parent_id, references(:locations, type: :binary_id, on_delete: :nilify_all), null: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:locations, [:user_id])

    create index(:locations, [:parent_id])

    create index(:locations, [:game_id])
  end
end
