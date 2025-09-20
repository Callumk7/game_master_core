defmodule GameMasterCore.Repo.Migrations.AddParentIdToNotes do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      add :parent_id, references(:notes, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:notes, [:parent_id])
  end
end
