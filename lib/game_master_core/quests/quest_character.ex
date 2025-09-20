defmodule GameMasterCore.Quests.QuestCharacter do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Characters.Character

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quests_characters" do
    belongs_to :quest, Quest
    belongs_to :character, Character

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_character, attrs) do
    quest_character
    |> cast(attrs, [
      :quest_id,
      :character_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:quest_id, :character_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint([:quest_id, :character_id])
  end
end
