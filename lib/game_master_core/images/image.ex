defmodule GameMasterCore.Images.Image do
  @moduledoc """
  Schema for storing image metadata and associations with game entities.

  Images are polymorphically associated with various entity types (characters, 
  factions, locations, quests) and support the concept of a "primary" image
  for each entity.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias GameMasterCore.Games.Game
  alias GameMasterCore.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Supported entity types for polymorphic association
  @valid_entity_types ["character", "faction", "location", "quest", "note"]

  # Supported image content types
  @valid_content_types [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/gif"
  ]

  # Maximum file size (10MB)
  @max_file_size 10 * 1024 * 1024

  schema "images" do
    field :filename, :string
    field :file_path, :string
    field :file_url, :string
    field :file_size, :integer
    field :content_type, :string
    field :alt_text, :string
    field :is_primary, :boolean, default: false
    field :entity_type, :string
    field :entity_id, :binary_id
    field :metadata, :map, default: %{}
    field :position_y, :integer, default: 50

    belongs_to :game, Game
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new image record.

  This is used when initially creating the image record before file upload.
  """
  def changeset(image, attrs, user_scope, game_id) do
    image
    |> cast(attrs, [
      :filename,
      :alt_text,
      :entity_type,
      :entity_id,
      :is_primary,
      :position_y
    ])
    |> validate_required([:filename, :entity_type, :entity_id])
    |> validate_entity_type()
    |> validate_filename()
    |> validate_position_y()
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end

  @doc """
  Changeset for updating image file information after successful upload.

  This is used to populate the file-related fields after the file has been
  successfully stored via the storage adapter.
  """
  def file_changeset(image, attrs) do
    image
    |> cast(attrs, [:file_path, :file_url, :file_size, :content_type, :metadata])
    |> validate_required([:file_path, :file_url, :file_size, :content_type])
    |> validate_content_type()
    |> validate_file_size()
  end

  @doc """
  Changeset for creating an image with complete file information.

  This is used when the file has already been stored and we have all
  the necessary information to create the database record.
  """
  def complete_changeset(image, attrs, user_scope, game_id) do
    image
    |> cast(attrs, [
      :filename,
      :file_path,
      :file_url,
      :file_size,
      :content_type,
      :alt_text,
      :entity_type,
      :entity_id,
      :is_primary,
      :metadata,
      :position_y
    ])
    |> validate_required([
      :filename,
      :file_path,
      :file_url,
      :file_size,
      :content_type,
      :entity_type,
      :entity_id
    ])
    |> validate_entity_type()
    |> validate_filename()
    |> validate_content_type()
    |> validate_file_size()
    |> validate_position_y()
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:game_id, game_id)
  end

  @doc """
  Changeset for updating image metadata (alt text, primary status, etc.).
  """
  def update_changeset(image, attrs) do
    image
    |> cast(attrs, [:alt_text, :is_primary, :metadata, :position_y])
    |> validate_length(:alt_text, max: 255)
    |> validate_position_y()
  end

  @doc """
  Get the list of valid entity types.
  """
  def valid_entity_types, do: @valid_entity_types

  @doc """
  Get the list of valid content types.
  """
  def valid_content_types, do: @valid_content_types

  @doc """
  Get the maximum allowed file size.
  """
  def max_file_size, do: @max_file_size

  # Private validation functions

  defp validate_entity_type(changeset) do
    validate_inclusion(changeset, :entity_type, @valid_entity_types,
      message: "must be one of: #{Enum.join(@valid_entity_types, ", ")}"
    )
  end

  defp validate_content_type(changeset) do
    validate_inclusion(changeset, :content_type, @valid_content_types,
      message: "must be a valid image type (JPEG, PNG, WebP, or GIF)"
    )
  end

  defp validate_file_size(changeset) do
    validate_number(changeset, :file_size,
      greater_than: 0,
      less_than_or_equal_to: @max_file_size,
      message: "must be less than #{@max_file_size / 1024 / 1024}MB"
    )
  end

  defp validate_filename(changeset) do
    changeset
    |> validate_length(:filename, min: 1, max: 255)
    |> validate_format(:filename, ~r/\.(jpe?g|png|webp|gif)$/i,
      message: "must be a valid image file (jpg, jpeg, png, webp, gif)"
    )
  end

  defp validate_position_y(changeset) do
    validate_number(changeset, :position_y,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      message: "must be between 0 and 100"
    )
  end
end
