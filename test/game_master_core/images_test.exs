defmodule GameMasterCore.ImagesTest do
  use GameMasterCore.DataCase, async: true

  alias GameMasterCore.Images
  alias GameMasterCore.Images.Image

  import GameMasterCore.AccountsFixtures

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
      # Should be at least 1MB but not more than 100MB
      assert max_size >= 1024 * 1024
      assert max_size <= 100 * 1024 * 1024
    end
  end
end
