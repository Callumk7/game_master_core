defmodule GameMasterCore.ImagesTest do
  use GameMasterCore.DataCase, async: true

  alias GameMasterCore.Images
  alias GameMasterCore.Images.Image

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.ImagesFixtures

  setup do
    scope = game_scope_fixture()

    {:ok, scope: scope}
  end

  describe "list_images_for_entity/4" do
    test "returns empty list when no images exist", %{scope: scope} do
      images = Images.list_images_for_entity(scope, "character", Ecto.UUID.generate())
      assert images == []
    end

    test "returns images for specific entity", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create test images using the Images context would require file uploads
      # For now, we'll test the basic query functionality
      images = Images.list_images_for_entity(scope, "character", entity_id)
      assert is_list(images)
    end

    test "works with note entity type", %{scope: scope} do
      note_id = Ecto.UUID.generate()
      images = Images.list_images_for_entity(scope, "note", note_id)
      assert images == []
    end
  end

  describe "get_primary_image/3" do
    test "returns error when no primary image exists", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      result = Images.get_primary_image(scope, "character", entity_id)
      assert {:error, :not_found} = result
    end
  end

  describe "get_image_stats/3" do
    test "returns zero stats when no images exist", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      stats = Images.get_image_stats(scope, "character", entity_id)

      assert %{
               total_count: 0,
               total_size: 0,
               has_primary: false
             } = stats
    end
  end

  describe "list_images_for_game/2" do
    test "returns empty list when no images exist in game", %{scope: scope} do
      images = Images.list_images_for_game(scope)
      assert images == []
    end

    test "accepts primary_first option", %{scope: scope} do
      images = Images.list_images_for_game(scope, primary_first: true)
      assert is_list(images)
      assert images == []
    end

    test "accepts limit option", %{scope: scope} do
      images = Images.list_images_for_game(scope, limit: 10)
      assert is_list(images)
      assert images == []
    end

    test "accepts offset option", %{scope: scope} do
      images = Images.list_images_for_game(scope, offset: 5)
      assert is_list(images)
      assert images == []
    end

    test "accepts multiple options", %{scope: scope} do
      images = Images.list_images_for_game(scope, primary_first: true, limit: 5, offset: 10)
      assert is_list(images)
      assert images == []
    end

    test "handles nil limit gracefully", %{scope: scope} do
      images = Images.list_images_for_game(scope, limit: nil)
      assert is_list(images)
      assert images == []
    end

    test "uses default offset of 0 when not specified", %{scope: scope} do
      # This test ensures our function doesn't crash with default offset
      images = Images.list_images_for_game(scope, limit: 10)
      assert is_list(images)
      assert images == []
    end
  end

  describe "image validation" do
    test "validates entity types" do
      valid_types = Image.valid_entity_types()
      assert "character" in valid_types
      assert "faction" in valid_types
      assert "location" in valid_types
      assert "quest" in valid_types
    end

    test "validates content types" do
      valid_types = Image.valid_content_types()
      assert "image/jpeg" in valid_types
      assert "image/png" in valid_types
      assert "image/webp" in valid_types
      assert "image/gif" in valid_types
    end

    test "has reasonable max file size" do
      max_size = Image.max_file_size()
      # Should be at least 1MB but not more than 100MB (currently 20MB)
      assert max_size >= 1024 * 1024
      assert max_size <= 100 * 1024 * 1024
      # Verify it's exactly 20MB
      assert max_size == 20 * 1024 * 1024
    end
  end

  describe "primary image management" do
    test "can set an image as primary", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create a regular image
      image = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})
      refute image.is_primary

      # Set it as primary
      {:ok, updated_image} = Images.set_as_primary(scope, image.id)
      assert updated_image.is_primary
    end

    test "setting an image as primary unsets other primary images for the same entity", %{
      scope: scope
    } do
      entity_id = Ecto.UUID.generate()

      # Create first image as primary
      image1 = primary_image_fixture(scope, "character", entity_id)
      assert image1.is_primary

      # Create second image as non-primary
      image2 = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})
      refute image2.is_primary

      # Set second image as primary
      {:ok, updated_image2} = Images.set_as_primary(scope, image2.id)
      assert updated_image2.is_primary

      # Verify first image is no longer primary
      {:ok, reloaded_image1} = Images.get_image_for_game(scope, image1.id)
      refute reloaded_image1.is_primary
    end

    test "can change primary image from one to another", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create multiple images for the same entity
      image1 = primary_image_fixture(scope, "character", entity_id)
      image2 = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})
      image3 = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})

      # Verify initial state
      assert image1.is_primary
      refute image2.is_primary
      refute image3.is_primary

      # Change primary to image2
      {:ok, updated_image2} = Images.set_as_primary(scope, image2.id)
      assert updated_image2.is_primary

      # Verify image1 and image3 are not primary
      {:ok, reloaded_image1} = Images.get_image_for_game(scope, image1.id)
      {:ok, reloaded_image3} = Images.get_image_for_game(scope, image3.id)
      refute reloaded_image1.is_primary
      refute reloaded_image3.is_primary

      # Change primary to image3
      {:ok, updated_image3} = Images.set_as_primary(scope, image3.id)
      assert updated_image3.is_primary

      # Verify image1 and image2 are not primary
      {:ok, reloaded_image1} = Images.get_image_for_game(scope, image1.id)
      {:ok, reloaded_image2} = Images.get_image_for_game(scope, image2.id)
      refute reloaded_image1.is_primary
      refute reloaded_image2.is_primary
    end

    test "primary status is isolated per entity", %{scope: scope} do
      entity1_id = Ecto.UUID.generate()
      entity2_id = Ecto.UUID.generate()

      # Create primary images for different entities
      image1 = primary_image_fixture(scope, "character", entity1_id)
      image2 = primary_image_fixture(scope, "character", entity2_id)

      # Both should remain primary since they're for different entities
      assert image1.is_primary
      assert image2.is_primary

      # Create another image for entity1 and set as primary
      image3 = image_fixture_for_entity(scope, "character", entity1_id, %{is_primary: false})
      {:ok, updated_image3} = Images.set_as_primary(scope, image3.id)
      assert updated_image3.is_primary

      # image1 should no longer be primary, but image2 should still be primary
      {:ok, reloaded_image1} = Images.get_image_for_game(scope, image1.id)
      {:ok, reloaded_image2} = Images.get_image_for_game(scope, image2.id)
      refute reloaded_image1.is_primary
      assert reloaded_image2.is_primary
    end

    test "primary status is isolated per entity type", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create primary images for same entity ID but different entity types
      character_image = primary_image_fixture(scope, "character", entity_id)
      location_image = primary_image_fixture(scope, "location", entity_id)

      # Both should remain primary since they're for different entity types
      assert character_image.is_primary
      assert location_image.is_primary

      # Create another character image and set as primary
      character_image2 =
        image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})

      {:ok, updated_character_image2} = Images.set_as_primary(scope, character_image2.id)
      assert updated_character_image2.is_primary

      # First character image should no longer be primary, but location image should still be primary
      {:ok, reloaded_character_image} = Images.get_image_for_game(scope, character_image.id)
      {:ok, reloaded_location_image} = Images.get_image_for_game(scope, location_image.id)
      refute reloaded_character_image.is_primary
      assert reloaded_location_image.is_primary
    end

    test "update_image can set primary status", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create a regular image
      image = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})
      refute image.is_primary

      # Update it to be primary using update_image
      {:ok, updated_image} = Images.update_image(scope, image.id, %{is_primary: true})
      assert updated_image.is_primary
    end

    test "update_image handles primary status change correctly", %{scope: scope} do
      entity_id = Ecto.UUID.generate()

      # Create first image as primary
      image1 = primary_image_fixture(scope, "character", entity_id)
      assert image1.is_primary

      # Create second image as non-primary
      image2 = image_fixture_for_entity(scope, "character", entity_id, %{is_primary: false})
      refute image2.is_primary

      # Update second image to be primary
      {:ok, updated_image2} =
        Images.update_image(scope, image2.id, %{is_primary: true, alt_text: "Updated alt text"})

      assert updated_image2.is_primary
      assert updated_image2.alt_text == "Updated alt text"

      # Verify first image is no longer primary
      {:ok, reloaded_image1} = Images.get_image_for_game(scope, image1.id)
      refute reloaded_image1.is_primary
    end
  end
end
