defmodule GameMasterCore.Characters.CharacterNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Notes.Note

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "character_notes" do
    belongs_to :character, Character
    belongs_to :note, Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_note, attrs) do
    character_note
    |> cast(attrs, [:character_id, :note_id])
    |> validate_required([:character_id, :note_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:character_id, :note_id])
  end
end
