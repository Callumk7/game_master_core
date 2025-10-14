defmodule GameMasterCore.Images do
  @moduledoc """
  Context module for managing images associated with game entities.

  This module provides functions for:
  - Creating and uploading images
  - Managing primary images
  - Querying images by entity
  - Deleting images and cleaning up files
  """

  import Ecto.Query, warn: false

  alias GameMasterCore.Repo
  alias GameMasterCore.Images.Image
  alias GameMasterCore.Storage
  alias GameMasterCore.Storage.KeyGenerator

  require Logger

  @doc """
  Get all images for a specific entity within a game scope.

  ## Examples

      iex> list_images_for_entity(scope, "character", character_id)
      [%Image{}, ...]
      
      iex> list_images_for_entity(scope, "character", character_id, primary_first: true)
      [%Image{is_primary: true}, %Image{is_primary: false}, ...]
  """
  def list_images_for_entity(scope, entity_type, entity_id, opts \\ []) do
    primary_first = Keyword.get(opts, :primary_first, false)

    query =
      from i in Image,
        where: i.game_id == ^scope.game.id,
        where: i.entity_type == ^entity_type,
        where: i.entity_id == ^entity_id

    query =
      if primary_first do
        from i in query, order_by: [desc: i.is_primary, desc: i.inserted_at]
      else
        from i in query, order_by: [desc: i.inserted_at]
      end

    Repo.all(query)
  end

  @doc """
  Get all images for a specific game.

  ## Examples

      iex> list_images_for_game(scope)
      [%Image{}, ...]
      
      iex> list_images_for_game(scope, primary_first: true)
      [%Image{is_primary: true}, %Image{is_primary: false}, ...]

      iex> list_images_for_game(scope, limit: 10, offset: 20)
      [%Image{}, ...] # limited results with pagination
  """
  def list_images_for_game(scope, opts \\ []) do
    primary_first = Keyword.get(opts, :primary_first, false)
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    query =
      from i in Image,
        where: i.game_id == ^scope.game.id

    query =
      if primary_first do
        from i in query, order_by: [desc: i.is_primary, desc: i.inserted_at]
      else
        from i in query, order_by: [desc: i.inserted_at]
      end

    query =
      if limit do
        from i in query, limit: ^limit, offset: ^offset
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Get the primary image for a specific entity.

  ## Examples

      iex> get_primary_image(scope, "character", character_id)
      {:ok, %Image{is_primary: true}}
      
      iex> get_primary_image(scope, "character", character_id)
      {:error, :not_found}
  """
  def get_primary_image(scope, entity_type, entity_id) do
    query =
      from i in Image,
        where: i.game_id == ^scope.game.id,
        where: i.entity_type == ^entity_type,
        where: i.entity_id == ^entity_id,
        where: i.is_primary == true

    case Repo.one(query) do
      nil -> {:error, :not_found}
      image -> {:ok, image}
    end
  end

  @doc """
  Get a specific image by ID within game scope.
  """
  def get_image_for_game(scope, image_id) do
    query =
      from i in Image,
        where: i.game_id == ^scope.game.id,
        where: i.id == ^image_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      image -> {:ok, image}
    end
  end

  @doc """
  Create and upload an image for an entity.

  This function handles the complete flow:
  1. Creates the image record
  2. Stores the file via the storage adapter
  3. Updates the record with file information
  4. Manages primary image logic

  ## Examples

      iex> create_image_for_entity(scope, upload, %{
      ...>   entity_type: "character",
      ...>   entity_id: character_id,
      ...>   alt_text: "Character portrait"
      ...> })
      {:ok, %Image{}}
      
      iex> create_image_for_entity(scope, invalid_upload, attrs)
      {:error, %Ecto.Changeset{}}
  """
  def create_image_for_entity(scope, %Plug.Upload{} = upload, attrs) do
    Repo.transaction(fn ->
      # Step 1: Store the file first to get storage information
      key =
        KeyGenerator.generate_key(
          scope.game.id,
          attrs.entity_type,
          attrs.entity_id,
          upload.filename
        )

      case Storage.store(upload.path, key, content_type: upload.content_type) do
        {:ok, %{url: url, metadata: storage_metadata}} ->
          # Step 2: Create the database record with complete file information
          file_size = Map.get(storage_metadata, :size, 0)

          complete_attrs =
            Map.merge(attrs, %{
              filename: upload.filename,
              file_path: key,
              file_url: url,
              file_size: file_size,
              content_type: upload.content_type,
              metadata: storage_metadata
            })

          case create_complete_image_record(scope, complete_attrs) do
            {:ok, image} ->
              # If this is marked as primary, unset other primary images
              if image.is_primary do
                unset_other_primary_images(
                  scope,
                  image.entity_type,
                  image.entity_id,
                  image.id
                )
              end

              image

            {:error, changeset} ->
              # Clean up the stored file if database creation fails
              Storage.delete(key)
              Repo.rollback(changeset)
          end

        {:error, reason} ->
          Logger.error("Failed to store image file: #{inspect(reason)}")
          Repo.rollback({:file_storage_failed, reason})
      end
    end)
  end

  @doc """
  Update image metadata (alt text, primary status, etc.).
  """
  def update_image(scope, image_id, attrs) do
    Repo.transaction(fn ->
      with {:ok, image} <- get_image_for_game(scope, image_id) do
        # If setting as primary, unset other primary images first
        if Map.get(attrs, :is_primary) || Map.get(attrs, "is_primary") do
          unset_other_primary_images(scope, image.entity_type, image.entity_id, image.id)
        end

        changeset = Image.update_changeset(image, attrs)

        case Repo.update(changeset) do
          {:ok, updated_image} -> updated_image
          {:error, reason} -> Repo.rollback(reason)
        end
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Set an image as the primary image for its entity.

  This automatically unsets any other primary images for the same entity.
  """
  def set_as_primary(scope, image_id) do
    update_image(scope, image_id, %{is_primary: true})
  end

  @doc """
  Delete an image and clean up the associated file.
  """
  def delete_image(scope, image_id) do
    Repo.transaction(fn ->
      with {:ok, image} <- get_image_for_game(scope, image_id),
           {:ok, _deleted_image} <- Repo.delete(image),
           :ok <- cleanup_image_file(image) do
        image
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Get statistics about images for an entity.
  """
  def get_image_stats(scope, entity_type, entity_id) do
    query =
      from i in Image,
        where: i.game_id == ^scope.game.id,
        where: i.entity_type == ^entity_type,
        where: i.entity_id == ^entity_id,
        select: %{
          total_count: count(i.id),
          total_size: sum(i.file_size),
          has_primary: fragment("bool_or(?)", i.is_primary)
        }

    case Repo.one(query) do
      %{total_count: 0} = stats ->
        %{stats | total_size: 0, has_primary: false}

      stats ->
        %{stats | total_size: stats.total_size || 0}
    end
  end

  @doc """
  Delete all images associated with a specific entity.

  This function is called when an entity is deleted to clean up
  all associated images and their files.
  """
  def delete_images_for_entity(scope, entity_type, entity_id) do
    images = list_images_for_entity(scope, entity_type, entity_id)

    Repo.transaction(fn ->
      Enum.each(images, fn image ->
        case Repo.delete(image) do
          {:ok, _deleted_image} ->
            cleanup_image_file(image)

          {:error, reason} ->
            Logger.error("Failed to delete image #{image.id}: #{inspect(reason)}")
            Repo.rollback(reason)
        end
      end)

      {:ok, length(images)}
    end)
  end

  # Private helper functions

  defp create_complete_image_record(scope, complete_attrs) do
    %Image{}
    |> Image.complete_changeset(complete_attrs, scope, scope.game.id)
    |> Repo.insert()
  end

  defp unset_other_primary_images(scope, entity_type, entity_id, exclude_image_id) do
    query =
      from i in Image,
        where: i.game_id == ^scope.game.id,
        where: i.entity_type == ^entity_type,
        where: i.entity_id == ^entity_id,
        where: i.id != ^exclude_image_id,
        where: i.is_primary == true

    Repo.update_all(query, set: [is_primary: false, updated_at: DateTime.utc_now()])
  end

  defp cleanup_image_file(image) do
    case Storage.delete(image.file_path) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Failed to delete image file #{image.file_path}: #{inspect(reason)}")
        # Don't fail the delete operation if file cleanup fails
        :ok
    end
  end
end
