defmodule GameMasterCore.Factions.FactionFaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Factions.Faction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "faction_factions" do
    belongs_to :faction_1, Faction
    belongs_to :faction_2, Faction
    field :relationship_type, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(faction_faction, attrs) do
    faction_faction
    |> cast(attrs, [:faction_1_id, :faction_2_id, :relationship_type])
    |> validate_required([:faction_1_id, :faction_2_id])
    |> validate_not_self_link()
    |> unique_constraint([:faction_1_id, :faction_2_id],
      name: :faction_factions_faction_1_id_faction_2_id_index
    )
  end

  defp validate_not_self_link(changeset) do
    faction_1_id = get_field(changeset, :faction_1_id)
    faction_2_id = get_field(changeset, :faction_2_id)

    if faction_1_id && faction_2_id && faction_1_id == faction_2_id do
      add_error(changeset, :faction_2_id, "cannot link faction to itself")
    else
      changeset
    end
  end
end
