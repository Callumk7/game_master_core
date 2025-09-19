defmodule GameMasterCore.Repo.Migrations.AddParentIdToQuests do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :parent_id, references(:quests, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:quests, [:parent_id])
  end
end
