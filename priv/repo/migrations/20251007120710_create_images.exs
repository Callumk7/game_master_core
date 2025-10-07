defmodule GameMasterCore.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string, null: false
      add :file_path, :string, null: false
      add :file_url, :string, null: false
      add :file_size, :bigint, null: false
      add :content_type, :string, null: false
      add :alt_text, :string
      add :is_primary, :boolean, default: false, null: false
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false
      add :metadata, :map, default: %{}

      # Foreign keys
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Indexes for efficient querying
    create index(:images, [:game_id])
    create index(:images, [:user_id])
    create index(:images, [:entity_type, :entity_id])
    create index(:images, [:entity_type, :entity_id, :is_primary])
    create index(:images, [:game_id, :entity_type, :entity_id])

    # Unique constraint to ensure only one primary image per entity
    create unique_index(:images, [:entity_type, :entity_id, :is_primary],
             where: "is_primary = true",
             name: :images_unique_primary_per_entity
           )
  end
end
