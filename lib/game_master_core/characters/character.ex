defmodule GameMasterCore.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "characters" do
    field :name, :string
    field :description, :string
    field :class, :string
    field :level, :integer
    field :image_url, :string

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
    |> cast(attrs, [:name, :description, :class, :level, :image_url])
    |> validate_required([:name, :class, :level])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end
end
