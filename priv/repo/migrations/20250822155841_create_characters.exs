defmodule GameMasterCore.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :name, :string
      add :description, :string
      add :class, :string
      add :level, :integer
      add :image_url, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:characters, [:user_id])
  end
end
