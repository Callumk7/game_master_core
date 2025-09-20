defmodule GameMasterCore.Repo.Migrations.AddParentTypeToNotes do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      add :parent_type, :string
    end

    create index(:notes, [:parent_type])
    create index(:notes, [:parent_id, :parent_type])
  end
end
