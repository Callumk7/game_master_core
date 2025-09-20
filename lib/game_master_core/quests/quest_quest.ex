defmodule GameMasterCore.Quests.QuestQuest do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quest_quests" do
    belongs_to :quest_1, Quest
    belongs_to :quest_2, Quest
    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(quest_quest, attrs) do
    quest_quest
    |> cast(attrs, [
      :quest_1_id,
      :quest_2_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:quest_1_id, :quest_2_id])
    |> validate_inclusion(:strength, 1..10)
    |> validate_not_self_link()
    |> unique_constraint([:quest_1_id, :quest_2_id],
      name: :quest_quests_quest_1_id_quest_2_id_index
    )
  end

  defp validate_not_self_link(changeset) do
    quest_1_id = get_field(changeset, :quest_1_id)
    quest_2_id = get_field(changeset, :quest_2_id)

    if quest_1_id && quest_2_id && quest_1_id == quest_2_id do
      add_error(changeset, :quest_2_id, "cannot link quest to itself")
    else
      changeset
    end
  end
end
