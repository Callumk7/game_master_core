defmodule GameMasterCore.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User
  alias GameMasterCore.Factions.Faction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "characters" do
    field :name, :string
    field :content, :string
    field :content_plain_text, :string
    field :class, :string
    field :level, :integer
    field :image_url, :string
    field :tags, {:array, :string}, default: []
    field :faction_role, :string
    field :pinned, :boolean, default: false

    belongs_to :game, Game
    belongs_to :user, User
    belongs_to :member_of_faction, Faction

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
      :image_url,
      :tags,
      :member_of_faction_id,
      :faction_role,
      :pinned
    ])
    |> validate_required([:name, :class, :level])
    |> validate_tags()
    |> validate_faction_role_when_member()
    |> foreign_key_constraint(:member_of_faction_id)
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

  defp validate_faction_role_when_member(changeset) do
    member_of_faction_id = get_field(changeset, :member_of_faction_id)
    faction_role = get_field(changeset, :faction_role)

    cond do
      # If member_of_faction_id is present but faction_role is blank
      member_of_faction_id && (is_nil(faction_role) || String.trim(faction_role) == "") ->
        add_error(
          changeset,
          :faction_role,
          "must be specified when character is a member of a faction"
        )

      true ->
        changeset
    end
  end
end
