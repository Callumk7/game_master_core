defmodule GameMasterCore.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  schema "notes" do
    field :name, :string
    field :content, :string

    belongs_to :game, Game
    belongs_to :user, User

    many_to_many :related_notes, __MODULE__,
      join_through: "note_notes",
      join_keys: [note_1_id: :id, note_2_id: :id]

    many_to_many :inverse_related_notes, __MODULE__,
      join_through: "note_notes",
      join_keys: [note_2_id: :id, note_1_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs, user_scope, game_id) do
    note
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end
end
