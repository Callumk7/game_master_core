defmodule GameMasterCore.Storage.KeyGenerator do
  @moduledoc """
  Utility module for generating consistent storage keys for files.

  This module provides various strategies for generating storage keys that
  organize files in a logical hierarchy while ensuring uniqueness.
  """

  @doc """
  Generate a storage key for an entity image.

  ## Parameters
  - game_id: The game UUID
  - entity_type: The type of entity ("character", "faction", etc.)
  - entity_id: The entity UUID
  - filename: The original filename

  ## Examples

      iex> GameMasterCore.Storage.KeyGenerator.generate_key(
      ...>   "123e4567-e89b-12d3-a456-426614174000",
      ...>   "character",
      ...>   "789e0123-e89b-12d3-a456-426614174000", 
      ...>   "avatar.jpg"
      ...> )
      "games/123e4567-e89b-12d3-a456-426614174000/character/789e0123-e89b-12d3-a456-426614174000/uuid.jpg"
  """
  @spec generate_key(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_key(game_id, entity_type, entity_id, filename) do
    extension = Path.extname(filename)
    uuid = Ecto.UUID.generate()

    "games/#{game_id}/#{entity_type}/#{entity_id}/#{uuid}#{extension}"
  end

  @doc """
  Generate a storage key with date-based organization.

  This variant includes the current date in the path for better organization
  of files over time.

  ## Parameters
  - game_id: The game UUID
  - entity_type: The type of entity ("character", "faction", etc.)
  - entity_id: The entity UUID
  - filename: The original filename
  - :with_date: Atom to indicate date-based organization

  ## Examples

      iex> GameMasterCore.Storage.KeyGenerator.generate_key(
      ...>   "123e4567-e89b-12d3-a456-426614174000",
      ...>   "character", 
      ...>   "789e0123-e89b-12d3-a456-426614174000",
      ...>   "avatar.jpg",
      ...>   :with_date
      ...> )
      "games/123e4567-e89b-12d3-a456-426614174000/character/789e0123-e89b-12d3-a456-426614174000/2025/01/07/uuid.jpg"
  """
  @spec generate_key(String.t(), String.t(), String.t(), String.t(), :with_date) :: String.t()
  def generate_key(game_id, entity_type, entity_id, filename, :with_date) do
    date_path = Date.utc_today() |> Date.to_string() |> String.replace("-", "/")
    extension = Path.extname(filename)
    uuid = Ecto.UUID.generate()

    "games/#{game_id}/#{entity_type}/#{entity_id}/#{date_path}/#{uuid}#{extension}"
  end

  @doc """
  Extract components from a storage key.

  This is useful for debugging or when you need to understand what
  a storage key represents.

  ## Examples

      iex> GameMasterCore.Storage.KeyGenerator.parse_key(
      ...>   "games/123e4567-e89b-12d3-a456-426614174000/character/789e0123-e89b-12d3-a456-426614174000/uuid.jpg"
      ...> )
      {:ok, %{
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        entity_type: "character", 
        entity_id: "789e0123-e89b-12d3-a456-426614174000",
        filename: "uuid.jpg"
      }}
  """
  @spec parse_key(String.t()) :: {:ok, map()} | {:error, :invalid_key}
  def parse_key(key) do
    case String.split(key, "/") do
      ["games", game_id, entity_type, entity_id, filename] ->
        {:ok,
         %{
           game_id: game_id,
           entity_type: entity_type,
           entity_id: entity_id,
           filename: filename
         }}

      ["games", game_id, entity_type, entity_id, _year, _month, _day, filename] ->
        {:ok,
         %{
           game_id: game_id,
           entity_type: entity_type,
           entity_id: entity_id,
           filename: filename
         }}

      _ ->
        {:error, :invalid_key}
    end
  end

  @doc """
  Generate a temporary key for file uploads before they are processed.

  ## Examples

      iex> GameMasterCore.Storage.KeyGenerator.generate_temp_key("image.jpg")
      "temp/uuid-image.jpg"
  """
  @spec generate_temp_key(String.t()) :: String.t()
  def generate_temp_key(filename) do
    uuid = Ecto.UUID.generate()
    extension = Path.extname(filename)
    basename = Path.basename(filename, extension)

    "temp/#{uuid}-#{basename}#{extension}"
  end
end
