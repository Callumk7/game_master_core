defmodule GameMasterCore.Characters.CharacterFaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Factions.Faction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "character_factions" do
    belongs_to :character, Character
    belongs_to :faction, Faction

    field :relationship_type, :string
    field :description, :string
    field :strength, :integer
    field :is_active, :boolean, default: true
    field :is_primary, :boolean, default: false
    field :faction_role, :string
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_faction, attrs) do
    character_faction
    |> cast(attrs, [
      :character_id,
      :faction_id,
      :relationship_type,
      :description,
      :strength,
      :is_active,
      :is_primary,
      :faction_role,
      :metadata
    ])
    |> validate_required([:character_id, :faction_id])
    |> validate_inclusion(:strength, 1..10)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:faction_id)
    |> unique_constraint([:character_id, :faction_id])
    |> maybe_check_primary_faction()
  end

  # A new private helper function to apply the constraint conditionally
  defp maybe_check_primary_faction(changeset) do
    # Only apply the check if is_primary is being set to true.
    # This prevents errors when un-setting a primary faction.
    if get_field(changeset, :is_primary) == true do
      unique_constraint(changeset, :is_primary,
        name: :character_factions_unique_primary_faction_index,
        message: "This character already has a primary faction"
      )
    else
      # If not primary, skip the check
      changeset
    end
  end
end
