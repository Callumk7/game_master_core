defmodule GameMasterCore.Quests.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  schema "quests" do
    field :name, :string
    field :content, :string

    belongs_to :game, Game
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest, attrs, game_scope, game_id) do
    quest
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
    |> put_change(:user_id, game_scope.user.id)
    |> put_change(:game_id, game_id)
  end
end
