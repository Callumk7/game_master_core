defmodule GameMasterCore.EntityShares.EntityShare do
  @moduledoc """
  Schema for tracking explicit entity sharing permissions.

  This allows users to grant specific access to their entities beyond
  the global visibility settings. Supports polymorphic entity references
  to work with all entity types (characters, factions, locations, quests, notes).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Accounts.User

  @type t :: %__MODULE__{
          id: binary(),
          entity_type: String.t(),
          entity_id: binary(),
          permission: String.t(),
          user: User.t(),
          user_id: binary(),
          shared_by: User.t(),
          shared_by_id: binary(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @entity_types ["character", "faction", "location", "quest", "note"]
  @permissions ["editor", "viewer", "blocked"]

  schema "entity_shares" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :permission, :string

    belongs_to :user, User
    belongs_to :shared_by, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating entity shares.

  ## Parameters
  - share: The EntityShare struct
  - attrs: Map with :entity_type, :entity_id, :user_id, :permission, :shared_by_id

  ## Validations
  - entity_type must be one of: #{inspect(@entity_types)}
  - permission must be one of: #{inspect(@permissions)}
  - All required fields must be present
  """
  def changeset(share, attrs) do
    share
    |> cast(attrs, [:entity_type, :entity_id, :user_id, :permission, :shared_by_id])
    |> validate_required([:entity_type, :entity_id, :user_id, :permission])
    |> validate_inclusion(:entity_type, @entity_types)
    |> validate_inclusion(:permission, @permissions)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:shared_by_id)
    |> unique_constraint([:entity_type, :entity_id, :user_id])
  end
end
