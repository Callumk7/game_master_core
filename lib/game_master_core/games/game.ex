defmodule GameMasterCore.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    field :name, :string
    field :content, :string
    field :content_plain_text, :string
    field :setting, :string

    many_to_many :members, GameMasterCore.Accounts.User, join_through: "game_members"
    belongs_to :owner, GameMasterCore.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs, _scope) do
    game
    |> cast(attrs, [:name, :content, :content_plain_text, :setting, :owner_id])
    |> validate_required([:name, :owner_id])
    |> foreign_key_constraint(:owner_id)
  end
end
