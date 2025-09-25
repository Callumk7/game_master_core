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
    field :parent_type, :string
    field :pinned, :boolean, default: false

    belongs_to :game, Game
    belongs_to :user, User
    belongs_to :parent, __MODULE__, foreign_key: :parent_id

    has_many :children, __MODULE__, foreign_key: :parent_id

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
      :parent_id,
      :parent_type,
      :pinned
    ])
    |> validate_required([:name, :content])
    |> validate_tags()
    |> validate_parent_type()
    |> validate_parent_note(game_id)
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

  @valid_parent_types ["character", "quest", "location", "faction"]

  defp validate_parent_type(changeset) do
    parent_id = get_field(changeset, :parent_id)
    parent_type = get_field(changeset, :parent_type)

    cond do
      is_nil(parent_id) and is_nil(parent_type) ->
        # Both nil is valid (no parent)
        changeset

      is_nil(parent_id) and not is_nil(parent_type) ->
        add_error(changeset, :parent_type, "cannot set parent_type without parent_id")

      not is_nil(parent_id) and is_nil(parent_type) ->
        # parent_id without parent_type means Note parent (backward compatibility)
        changeset

      parent_type not in @valid_parent_types ->
        add_error(
          changeset,
          :parent_type,
          "must be one of: #{Enum.join(@valid_parent_types, ", ")}"
        )

      true ->
        changeset
    end
  end

  defp validate_parent_note(changeset, game_id) do
    case get_field(changeset, :parent_id) do
      nil ->
        changeset

      parent_id ->
        parent_type = get_field(changeset, :parent_type)
        note_id = get_field(changeset, :id)

        cond do
          note_id && note_id == parent_id ->
            add_error(changeset, :parent_id, "note cannot be its own parent")

          is_nil(parent_type) ->
            # Backward compatibility: parent_type nil means Note parent
            validate_note_parent(changeset, parent_id, game_id, note_id)

          parent_type in @valid_parent_types ->
            validate_polymorphic_parent(changeset, parent_id, parent_type, game_id)

          true ->
            changeset
        end
    end
  end

  defp validate_note_parent(changeset, parent_id, game_id, note_id) do
    cond do
      not parent_note_exists_in_game?(parent_id, game_id) ->
        add_error(
          changeset,
          :parent_id,
          "parent note does not exist or does not belong to the same game"
        )

      would_create_cycle?(note_id, parent_id) ->
        add_error(changeset, :parent_id, "would create a circular reference")

      true ->
        changeset
    end
  end

  defp validate_polymorphic_parent(changeset, parent_id, parent_type, game_id) do
    if polymorphic_parent_exists_in_game?(parent_id, parent_type, game_id) do
      changeset
    else
      add_error(
        changeset,
        :parent_id,
        "parent #{parent_type} does not exist or does not belong to the same game"
      )
    end
  end

  defp parent_note_exists_in_game?(parent_id, game_id) do
    case GameMasterCore.Repo.get(__MODULE__, parent_id) do
      nil -> false
      note -> note.game_id == game_id
    end
  end

  defp polymorphic_parent_exists_in_game?(parent_id, parent_type, game_id) do
    module =
      case parent_type do
        "character" -> GameMasterCore.Characters.Character
        "quest" -> GameMasterCore.Quests.Quest
        "location" -> GameMasterCore.Locations.Location
        "faction" -> GameMasterCore.Factions.Faction
        _ -> nil
      end

    case module && GameMasterCore.Repo.get(module, parent_id) do
      nil -> false
      entity -> entity.game_id == game_id
    end
  end

  defp would_create_cycle?(nil, _parent_id), do: false

  defp would_create_cycle?(note_id, parent_id) do
    check_cycle(parent_id, note_id, MapSet.new())
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
          note -> check_cycle(note.parent_id, target_id, MapSet.put(visited, current_id))
        end
    end
  end
end
