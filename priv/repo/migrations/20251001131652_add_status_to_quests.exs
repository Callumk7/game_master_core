defmodule GameMasterCore.Repo.Migrations.AddStatusToQuests do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :status, :string, default: "preparing", null: false
    end
  end
end
