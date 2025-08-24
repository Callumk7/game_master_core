defmodule GameMasterCore.Factions.FactionNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Notes.Note

  schema "faction_notes" do
    belongs_to :faction, Faction
    belongs_to :note, Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction_note, attrs) do
    faction_note
    |> cast(attrs, [:faction_id, :note_id])
    |> validate_required([:faction_id, :note_id])
    |> foreign_key_constraint(:faction_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:faction_id, :note_id])
  end
end
