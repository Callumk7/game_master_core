defmodule GameMasterCore.Repo.Migrations.CreateEntityShares do
  use Ecto.Migration

  def change do
    create table(:entity_shares, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Polymorphic entity reference
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false

      # User being granted access
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      # Permission level: "editor", "viewer", "blocked"
      add :permission, :string, null: false

      # Who granted this permission (for audit trail)
      add :shared_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # Indexes for performance
    create index(:entity_shares, [:entity_type, :entity_id])
    create index(:entity_shares, [:user_id])
    create unique_index(:entity_shares, [:entity_type, :entity_id, :user_id])
  end
end
