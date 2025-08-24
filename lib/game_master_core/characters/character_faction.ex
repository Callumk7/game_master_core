defmodule GameMasterCore.Characters.CharacterFaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Factions.Faction

  schema "character_factions" do
    belongs_to :character, Character
    belongs_to :faction, Faction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_faction, attrs) do
    character_faction
    |> cast(attrs, [:character_id, :faction_id])
    |> validate_required([:character_id, :faction_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:faction_id)
    |> unique_constraint([:character_id, :faction_id])
  end
end
