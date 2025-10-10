defmodule GameMasterCore.Repo.Migrations.PrimaryFactionInJoinTable do
  use Ecto.Migration

  def change do
    alter table(:character_factions) do
      add :is_primary, :boolean, default: false, null: false
      add :faction_role, :string
    end
  end
end
