defmodule GameMasterCoreWeb.ImageJSON do
  @moduledoc """
  JSON views for image responses.
  """

  alias GameMasterCore.Images.Image

  @doc """
  Renders a list of images.
  """
  def index(%{images: images, entity_type: entity_type, entity_id: entity_id}) do
    %{
      data: for(image <- images, do: data(image)),
      meta: %{
        entity_type: entity_type,
        entity_id: entity_id,
        total_count: length(images)
      }
    }
  end

  @doc """
  Renders a single image.
  """
  def show(%{image: image}) do
    %{data: data(image)}
  end

  @doc """
  Renders image statistics.
  """
  def stats(%{stats: stats, entity_type: entity_type, entity_id: entity_id}) do
    %{
      data: %{
        entity_type: entity_type,
        entity_id: entity_id,
        total_count: stats.total_count,
        total_size: stats.total_size,
        total_size_mb: format_size_mb(stats.total_size),
        has_primary: stats.has_primary
      }
    }
  end

  @doc """
  Renders a list of images for a game.
  """
  def game_images(%{images: images}) do
    %{
      data: for(image <- images, do: data(image)),
      meta: %{
        total_count: length(images)
      }
    }
  end

  defp data(%Image{} = image) do
    %{
      id: image.id,
      filename: image.filename,
      file_url: image.file_url,
      file_size: image.file_size,
      file_size_mb: format_size_mb(image.file_size),
      content_type: image.content_type,
      alt_text: image.alt_text,
      is_primary: image.is_primary,
      entity_type: image.entity_type,
      entity_id: image.entity_id,
      metadata: image.metadata,
      inserted_at: image.inserted_at,
      updated_at: image.updated_at
    }
  end

  defp format_size_mb(size) when is_integer(size) do
    Float.round(size / 1024 / 1024, 2)
  end

  defp format_size_mb(_), do: 0.0
end
