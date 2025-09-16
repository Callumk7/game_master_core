defmodule GameMasterCore.Locations.Location do
  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "locations" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :tags, {:array, :string}, default: []

    # Self-referencing relationships
    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    belongs_to :user, User
    belongs_to :game, Game

    many_to_many :related_locations, __MODULE__,
      join_through: "location_locations",
      join_keys: [location_1_id: :id, location_2_id: :id]

    many_to_many :inverse_related_locations, __MODULE__,
      join_through: "location_locations",
      join_keys: [location_2_id: :id, location_1_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location, attrs, user_scope, game_id) do
    location
    |> cast(attrs, [:name, :description, :type, :parent_id, :tags])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, [
      "continent",
      "nation",
      "region",
      "city",
      "settlement",
      "building",
      "complex"
    ])
    |> foreign_key_constraint(:parent_id)
    |> validate_not_self_parent()
    |> validate_tags()
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end

  defp validate_not_self_parent(changeset) do
    parent_id = get_field(changeset, :parent_id)
    id = get_field(changeset, :id)

    if parent_id && id && parent_id == id do
      add_error(changeset, :parent_id, "cannot be the same as the location's own ID")
    else
      changeset
    end
  end

  def put_parent(changeset, %__MODULE__{} = parent) do
    put_change(changeset, :parent_id, parent.id)
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
