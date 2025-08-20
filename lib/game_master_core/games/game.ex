defmodule GameMasterCore.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :description, :string
    field :setting, :string

    many_to_many :members, GameMasterCore.Accounts.User, join_through: "game_members"
    belongs_to :owner, GameMasterCore.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs, _scope) do
    game
    |> cast(attrs, [:name, :description, :setting, :owner_id])
    |> validate_required([:name, :owner_id])
    |> foreign_key_constraint(:owner_id)
  end
end
