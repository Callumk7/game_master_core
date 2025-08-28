defmodule GameMasterCore.Locations.LocationNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Notes.Note

  schema "location_notes" do
    belongs_to :location, Location
    belongs_to :note, Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location_note, attrs) do
    location_note
    |> cast(attrs, [:location_id, :note_id])
    |> validate_required([:location_id, :note_id])
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:location_id, :note_id])
  end
end
