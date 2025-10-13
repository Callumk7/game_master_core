defmodule GameMasterCore.Repo.Migrations.UniquePrimaryFactionIndex do
  use Ecto.Migration

  def change do
    create unique_index(:character_factions, [:character_id],
             where: "is_primary = true",
             name: :character_factions_unique_primary_faction_index
           )
  end
end
