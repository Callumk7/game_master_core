defmodule GameMasterCore.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "characters" do
    field :name, :string
    field :content, :string
    field :content_plain_text, :string
    field :class, :string
    field :level, :integer
    field :tags, {:array, :string}, default: []
    field :pinned, :boolean, default: false
    field :race, :string
    field :alive, :boolean, default: true

    belongs_to :game, Game
    belongs_to :user, User

    many_to_many :related_characters, __MODULE__,
      join_through: "character_characters",
      join_keys: [character_1_id: :id, character_2_id: :id]

    many_to_many :inverse_related_characters, __MODULE__,
      join_through: "character_characters",
      join_keys: [character_2_id: :id, character_1_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character, attrs, user_scope, game_id) do
    character
    |> cast(attrs, [
      :name,
      :content,
      :content_plain_text,
      :class,
      :level,
      :tags,
      :pinned,
      :race,
      :alive
    ])
    |> validate_required([:name, :class, :level])
    |> validate_tags()
    |> put_change(:user_id, user_scope.user.id)
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
