defmodule GameMasterCore.Games.GameMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  schema "game_members" do
    belongs_to :user, User
    belongs_to :game, Game
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime
    field :status, :string, default: "active"

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :joined_at, :status])
    |> maybe_put_joined_at()
    |> validate_required([:role, :joined_at])
    |> validate_inclusion(:role, ["member", "owner"])
    |> validate_inclusion(:status, ["active", "inactive", "banned"])
  end

  defp maybe_put_joined_at(changeset) do
    case get_field(changeset, :joined_at) do
      nil -> put_change(changeset, :joined_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
