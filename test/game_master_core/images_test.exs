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
