defmodule GameMasterCore.Quests.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "quests" do
    field :name, :string
    field :content, :string

    belongs_to :game, Game
    belongs_to :user, User

    many_to_many :related_quests, __MODULE__,
      join_through: "quest_quests",
      join_keys: [quest_1_id: :id, quest_2_id: :id]

    many_to_many :inverse_related_quests, __MODULE__,
      join_through: "quest_quests",
      join_keys: [quest_2_id: :id, quest_1_id: :id]

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
