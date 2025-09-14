defmodule GameMasterCore.Notes.NoteNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Notes.Note

  schema "note_notes" do
    belongs_to :note_1, Note
    belongs_to :note_2, Note
    field :relationship_type, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(note_note, attrs) do
    note_note
    |> cast(attrs, [:note_1_id, :note_2_id, :relationship_type])
    |> validate_required([:note_1_id, :note_2_id])
    |> validate_not_self_link()
    |> unique_constraint([:note_1_id, :note_2_id],
      name: :note_notes_note_1_id_note_2_id_index
    )
  end

  defp validate_not_self_link(changeset) do
    note_1_id = get_field(changeset, :note_1_id)
    note_2_id = get_field(changeset, :note_2_id)

    if note_1_id && note_2_id && note_1_id == note_2_id do
      add_error(changeset, :note_2_id, "cannot link note to itself")
    else
      changeset
    end
  end
end
