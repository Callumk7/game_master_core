defmodule GameMasterCore.Locations.LocationLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "location_locations" do
    belongs_to :location_1, Location
    belongs_to :location_2, Location
    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(location_location, attrs) do
    location_location
    |> cast(attrs, [
      :location_1_id,
      :location_2_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:location_1_id, :location_2_id])
    |> validate_inclusion(:strength, 1..10)
    |> validate_not_self_link()
    |> unique_constraint([:location_1_id, :location_2_id],
      name: :location_locations_location_1_id_location_2_id_index
    )
  end

  defp validate_not_self_link(changeset) do
    location_1_id = get_field(changeset, :location_1_id)
    location_2_id = get_field(changeset, :location_2_id)

    if location_1_id && location_2_id && location_1_id == location_2_id do
      add_error(changeset, :location_2_id, "cannot link location to itself")
    else
      changeset
    end
  end
end
