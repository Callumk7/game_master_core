defmodule GameMasterCore.Characters.CharacterCharacter do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Characters.Character

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "character_characters" do
    belongs_to :character_1, Character
    belongs_to :character_2, Character
    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(character_character, attrs) do
    character_character
    |> cast(attrs, [
      :character_1_id,
      :character_2_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:character_1_id, :character_2_id])
    |> validate_inclusion(:strength, 1..10)
    |> validate_not_self_link()
    |> unique_constraint([:character_1_id, :character_2_id],
      name: :character_characters_character_1_id_character_2_id_index
    )
  end

  defp validate_not_self_link(changeset) do
    character_1_id = get_field(changeset, :character_1_id)
    character_2_id = get_field(changeset, :character_2_id)

    if character_1_id && character_2_id && character_1_id == character_2_id do
      add_error(changeset, :character_2_id, "cannot link character to itself")
    else
      changeset
    end
  end
end
