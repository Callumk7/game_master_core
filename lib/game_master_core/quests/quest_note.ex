defmodule GameMasterCore.Quests.QuestNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Notes.Note

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quests_notes" do
    belongs_to :quest, Quest
    belongs_to :note, Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_note, attrs) do
    quest_note
    |> cast(attrs, [:quest_id, :note_id])
    |> validate_required([:quest_id, :note_id])
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:note_id)
    |> unique_constraint([:quest_id, :note_id])
  end
end
