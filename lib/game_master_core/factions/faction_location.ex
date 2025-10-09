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

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :is_current_location, :boolean, default: false
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction_location, attrs) do
    faction_location
    |> cast(attrs, [
      :faction_id,
      :location_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :is_current_location,
      :metadata
    ])
    |> validate_required([:faction_id, :location_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:faction_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint([:location_id, :faction_id])
  end
end
