defmodule GameMasterCore.Factions.Faction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "factions" do
    field :name, :string
    field :description, :string

    belongs_to :game, Game
    belongs_to :user, User

    many_to_many :related_factions, __MODULE__,
      join_through: "faction_factions",
      join_keys: [faction_1_id: :id, faction_2_id: :id]

    many_to_many :inverse_related_factions, __MODULE__,
      join_through: "faction_factions",
      join_keys: [faction_2_id: :id, faction_1_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faction, attrs, user_scope, game_id) do
    faction
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end
end
