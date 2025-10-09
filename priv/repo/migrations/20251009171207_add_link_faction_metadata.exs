defmodule GameMasterCore.Repo.Migrations.AddLinkFactionMetadata do
  use Ecto.Migration

  def change do
    alter table(:faction_locations) do
      add :is_current_location, :boolean, default: false, null: false
    end
  end
end
