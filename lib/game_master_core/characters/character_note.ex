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

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_note, attrs) do
    character_note
    |> cast(attrs, [
      :character_id,
      :note_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:character_id, :note_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:character_id, :note_id])
  end
end
