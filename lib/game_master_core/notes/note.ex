defmodule GameMasterCore.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notes" do
    field :name, :string
    field :content, :string
    field :content_plain_text, :string
    field :tags, {:array, :string}, default: []
    field :pinned, :boolean, default: false
    field :visibility, :string, default: "private"

    # Virtual fields for permission metadata (calculated in context layer)
    field :can_edit, :boolean, virtual: true
    field :can_delete, :boolean, virtual: true
    field :can_share, :boolean, virtual: true

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
    |> cast(attrs, [
      :name,
      :content,
      :content_plain_text,
      :tags,
      :pinned,
      :visibility
    ])
    |> validate_required([:name])
    |> validate_inclusion(:visibility, ["private", "viewable", "editable"])
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
