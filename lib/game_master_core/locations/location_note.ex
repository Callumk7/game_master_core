defmodule GameMasterCore.Locations.LocationNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Notes.Note

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "location_notes" do
    belongs_to :location, Location
    belongs_to :note, Note

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location_note, attrs) do
    location_note
    |> cast(attrs, [
      :location_id,
      :note_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:location_id, :note_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:location_id, :note_id])
  end
end
