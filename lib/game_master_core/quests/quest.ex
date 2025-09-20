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
    field :content_plain_text, :string
    field :tags, {:array, :string}, default: []

    belongs_to :game, Game
    belongs_to :user, User
    belongs_to :parent, __MODULE__, foreign_key: :parent_id

    has_many :children, __MODULE__, foreign_key: :parent_id

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
    |> cast(attrs, [:name, :content, :content_plain_text, :tags, :parent_id])
    |> validate_required([:name, :content])
    |> validate_tags()
    |> validate_parent_quest(game_id)
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

  defp validate_parent_quest(changeset, game_id) do
    case get_field(changeset, :parent_id) do
      nil ->
        changeset

      parent_id ->
        quest_id = get_field(changeset, :id)

        cond do
          quest_id && quest_id == parent_id ->
            add_error(changeset, :parent_id, "quest cannot be its own parent")

          not parent_quest_exists_in_game?(parent_id, game_id) ->
            add_error(
              changeset,
              :parent_id,
              "parent quest does not exist or does not belong to the same game"
            )

          would_create_cycle?(quest_id, parent_id) ->
            add_error(changeset, :parent_id, "would create a circular reference")

          true ->
            changeset
        end
    end
  end

  defp parent_quest_exists_in_game?(parent_id, game_id) do
    case GameMasterCore.Repo.get(__MODULE__, parent_id) do
      nil -> false
      quest -> quest.game_id == game_id
    end
  end

  defp would_create_cycle?(nil, _parent_id), do: false

  defp would_create_cycle?(quest_id, parent_id) do
    check_cycle(parent_id, quest_id, MapSet.new())
  end

  defp check_cycle(nil, _target_id, _visited), do: false

  defp check_cycle(current_id, target_id, visited) do
    cond do
      current_id == target_id ->
        true

      MapSet.member?(visited, current_id) ->
        false

      true ->
        case GameMasterCore.Repo.get(__MODULE__, current_id) do
          nil -> false
          quest -> check_cycle(quest.parent_id, target_id, MapSet.put(visited, current_id))
        end
    end
  end
end
