defmodule GameMasterCore.Repo.Migrations.RemoveNotesParentIdFkeyForPolymorphic do
  use Ecto.Migration

  def change do
    # Remove the foreign key constraint on parent_id since we now use polymorphic relationships
    drop constraint(:notes, "notes_parent_id_fkey")
  end
end
