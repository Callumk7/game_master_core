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

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_character, attrs) do
    quest_character
    |> cast(attrs, [:quest_id, :character_id])
    |> validate_required([:quest_id, :character_id])
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:character_id)
    |> unique_constraint([:quest_id, :character_id])
  end
end
