defmodule GameMasterCore.Quests.QuestFaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Factions.Faction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quests_factions" do
    belongs_to :quest, Quest
    belongs_to :faction, Faction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest_faction, attrs) do
    quest_faction
    |> cast(attrs, [:quest_id, :faction_id])
    |> validate_required([:quest_id, :faction_id])
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:faction_id)
    |> unique_constraint([:quest_id, :faction_id])
  end
end
