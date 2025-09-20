defmodule GameMasterCore.Factions.FactionNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Notes.Note

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "faction_notes" do
    belongs_to :faction, Faction
    belongs_to :note, Note

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction_note, attrs) do
    faction_note
    |> cast(attrs, [
      :faction_id,
      :note_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:faction_id, :note_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:faction_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:faction_id, :note_id])
  end
end
