defmodule GameMasterCore.Quests.QuestLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Locations.Location

  schema "quests_locations" do
    belongs_to :quest, Quest
    belongs_to :location, Location

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_location, attrs) do
    quest_location
    |> cast(attrs, [:quest_id, :location_id])
    |> validate_required([:quest_id, :location_id])
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:location_id)
    |> unique_constraint([:quest_id, :location_id])
  end
end
