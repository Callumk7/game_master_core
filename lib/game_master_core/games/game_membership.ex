defmodule GameMasterCore.Games.GameMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "game_members" do
    belongs_to :user, User
    belongs_to :game, Game
    field :role, :string, default: "member"

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :game_id, :role])
    |> validate_required([:user_id, :game_id, :role])
    |> validate_inclusion(:role, ["admin", "game_master", "member"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:user_id, :game_id])
  end
end
