defmodule GameMasterCore.Factions.Faction do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  schema "factions" do
    field :name, :string
    field :description, :string

    belongs_to :game, Game
    belongs_to :user, User

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
