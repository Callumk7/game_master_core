defmodule GameMasterCore.Repo.Migrations.AddUniqueCurrentLocationForCharacterAndFaction do
  use Ecto.Migration

  def change do
    create unique_index(:character_locations, [:character_id],
             where: "is_current_location = true",
             name: :character_locations_unique_current_location_index
           )

    create unique_index(:faction_locations, [:faction_id],
             where: "is_current_location = true",
             name: :faction_locations_unique_current_location_index
           )
  end
end
