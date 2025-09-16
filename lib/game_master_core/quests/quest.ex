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
    field :tags, {:array, :string}, default: []

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
    |> cast(attrs, [:name, :content, :tags])
    |> validate_required([:name, :content])
    |> validate_tags()
    |> put_change(:user_id, game_scope.user.id)
    |> put_change(:game_id, game_id)
  end

  defp validate_tags(changeset) do
    tags = get_field(changeset, :tags) || []
    
    cond do
      length(tags) > 20 ->
        add_error(changeset, :tags, "cannot have more than 20 tags")
      
      Enum.any?(tags, &(String.length(&1) > 50)) ->
        add_error(changeset, :tags, "individual tags cannot be longer than 50 characters")
      
      tags != Enum.uniq(tags) ->
        add_error(changeset, :tags, "cannot have duplicate tags")
      
      true ->
        changeset
    end
  end
end
