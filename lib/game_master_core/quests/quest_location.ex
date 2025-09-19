defmodule GameMasterCore.Quests.QuestLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quests_locations" do
    belongs_to :quest, Quest
    belongs_to :location, Location

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_location, attrs) do
    quest_location
    |> cast(attrs, [
      :quest_id,
      :location_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :metadata
    ])
    |> validate_required([:quest_id, :location_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint([:quest_id, :location_id])
  end
end
