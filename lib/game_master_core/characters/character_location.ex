defmodule GameMasterCore.Characters.CharacterLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "character_locations" do
    belongs_to :character, Character
    belongs_to :location, Location

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_location, attrs) do
    character_location
    |> cast(attrs, [
      :character_id,
      :location_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:character_id, :location_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint([:location_id, :character_id])
  end
end
