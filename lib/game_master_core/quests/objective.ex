defmodule GameMasterCore.Quests.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Notes.Note

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "objectives" do
    field :body, :string
    field :complete, :boolean, default: false

    belongs_to :quest, Quest
    belongs_to :note_link, Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [:body, :complete, :quest_id, :note_link_id])
    |> validate_required([:body, :quest_id])
    |> validate_length(:body, min: 1, max: 1000)
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:note_link_id)
  end
end
