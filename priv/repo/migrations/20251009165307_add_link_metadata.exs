defmodule GameMasterCore.Repo.Migrations.AddLinkMetadata do
  use Ecto.Migration

  def change do
    alter table(:character_locations) do
      add :is_current_location, :boolean, default: false, null: false
    end
  end
end
