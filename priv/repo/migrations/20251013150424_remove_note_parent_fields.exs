defmodule GameMasterCore.Repo.Migrations.RemoveNoteParentFields do
  use Ecto.Migration

  def change do
    # Remove indexes first
    drop index(:notes, [:parent_id])
    drop index(:notes, [:parent_type])
    drop index(:notes, [:parent_id, :parent_type])
    
    # Remove columns
    alter table(:notes) do
      remove :parent_id, :binary_id
      remove :parent_type, :string
    end
  end
end
