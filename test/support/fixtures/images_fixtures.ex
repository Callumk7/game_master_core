defmodule GameMasterCore.ImagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  image entities for testing purposes.
  """

  alias GameMasterCore.Images.Image
  alias GameMasterCore.Repo

  def valid_image_attributes(attrs \\ %{}) do
    entity_id = Ecto.UUID.generate()
    unique_id = System.unique_integer([:positive])

    Enum.into(attrs, %{
      filename: "test_image_#{unique_id}.jpg",
      file_path: "/uploads/test_image_#{unique_id}.jpg",
      file_url: "http://localhost:4000/uploads/test_image_#{unique_id}.jpg",
      # 100KB
      file_size: 1024 * 100,
      content_type: "image/jpeg",
      alt_text: "Test image #{unique_id}",
      entity_type: "character",
      entity_id: entity_id,
      is_primary: false,
      metadata: %{},
      position_y: 50
    })
  end

  def image_fixture(scope, attrs \\ %{}) do
    attrs = valid_image_attributes(attrs)

    %Image{}
    |> Image.complete_changeset(attrs, scope, scope.game.id)
    |> Repo.insert!()
  end

  def image_fixture_for_entity(scope, entity_type, entity_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:entity_type, entity_type)
      |> Map.put(:entity_id, entity_id)

    image_fixture(scope, attrs)
  end

  def primary_image_fixture(scope, entity_type, entity_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:entity_type, entity_type)
      |> Map.put(:entity_id, entity_id)
      |> Map.put(:is_primary, true)

    image_fixture(scope, attrs)
  end
end
