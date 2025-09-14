defmodule GameMasterCore.Factions.FactionLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "faction_locations" do
    belongs_to :faction, Faction
    belongs_to :location, Location

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction_location, attrs) do
    faction_location
    |> cast(attrs, [:faction_id, :location_id])
    |> validate_required([:faction_id, :location_id])
    |> foreign_key_constraint(:faction_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint([:location_id, :faction_id])
  end
end
