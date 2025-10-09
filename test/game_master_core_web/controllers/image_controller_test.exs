defmodule GameMasterCoreWeb.ImageControllerTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCore.GamesFixtures

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, game: game}
  end

  describe "GET /api/games/:game_id/characters/:character_id/images" do
    test "returns empty list when no images exist", %{conn: conn, game: game} do
      character_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images")

      assert json_response(conn, 200)["data"] == []
    end

    test "returns 404 for invalid entity type", %{conn: conn, game: game} do
      entity_id = Ecto.UUID.generate()

      # This should fail because "invalid_type" is not a valid entity type
      conn = get(conn, "/api/games/#{game.id}/invalid_types/#{entity_id}/images")

      assert response(conn, 404)
    end

    test "works with note entity type", %{conn: conn, game: game} do
      note_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note_id}/images")

      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "GET /api/games/:game_id/characters/:character_id/images/stats" do
    test "returns zero stats when no images exist", %{conn: conn, game: game} do
      character_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/stats")

      response_data = json_response(conn, 200)["data"]

      assert response_data["total_count"] == 0
      assert response_data["total_size"] == 0
      assert response_data["has_primary"] == false
      assert response_data["entity_type"] == "character"
      assert response_data["entity_id"] == character_id
    end
  end

  describe "GET /api/games/:game_id/notes/:note_id/images/stats" do
    test "returns zero stats when no images exist for note", %{conn: conn, game: game} do
      note_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note_id}/images/stats")

      response_data = json_response(conn, 200)["data"]

      assert response_data["total_count"] == 0
      assert response_data["total_size"] == 0
      assert response_data["has_primary"] == false
      assert response_data["entity_type"] == "note"
      assert response_data["entity_id"] == note_id
    end
  end

  describe "POST /api/games/:game_id/characters/:character_id/images" do
    test "requires authentication", %{game: game} do
      # Create a new connection without authentication
      conn = build_conn()
      character_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images", %{
          image: %{file: "fake_upload"}
        })

      # Should redirect to login or return unauthorized
      assert conn.status in [401, 302]
    end

    # Note: Testing actual file uploads requires more complex setup
    # with temporary files and proper Plug.Upload structs
    test "returns error for missing file", %{conn: conn, game: game} do
      character_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images", %{
          image: %{alt_text: "Test image"}
        })

      # Should return an error for missing file
      assert json_response(conn, 400) || json_response(conn, 422)
    end
  end

  describe "route parameter extraction" do
    test "extracts character entity info correctly", %{conn: conn, game: game} do
      character_id = Ecto.UUID.generate()

      # This tests that our route structure works correctly
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images")

      # Should not return a 404 for route matching
      refute conn.status == 404
    end
  end

  describe "GET /api/games/:game_id/images" do
    test "returns empty list when no images exist in game", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images")

      response_data = json_response(conn, 200)
      assert response_data["data"] == []
      assert response_data["meta"]["total_count"] == 0
    end

    test "requires authentication", %{game: game} do
      # Create a new connection without authentication
      conn = build_conn()

      conn = get(conn, ~p"/api/games/#{game.id}/images")

      # Should redirect to login or return unauthorized
      assert conn.status in [401, 302]
    end

    test "accepts primary_first query parameter", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?primary_first=true")

      assert json_response(conn, 200)["data"] == []
    end

    test "accepts limit query parameter", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?limit=10")

      assert json_response(conn, 200)["data"] == []
    end

    test "accepts offset query parameter", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?offset=5")

      assert json_response(conn, 200)["data"] == []
    end

    test "accepts multiple query parameters", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?primary_first=true&limit=5&offset=10")

      response_data = json_response(conn, 200)
      assert response_data["data"] == []
      assert response_data["meta"]["total_count"] == 0
    end

    test "ignores invalid limit parameter", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?limit=invalid")

      # Should not error and return empty list
      assert json_response(conn, 200)["data"] == []
    end

    test "ignores invalid offset parameter", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/images?offset=invalid")

      # Should not error and return empty list
      assert json_response(conn, 200)["data"] == []
    end

    test "returns 404 for non-existent game", %{conn: conn} do
      fake_game_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{fake_game_id}/images")

      assert response(conn, 404)
    end
  end

  describe "PUT /api/games/:game_id/characters/:character_id/images/:id" do
    setup %{game: game} do
      character_id = Ecto.UUID.generate()
      
      # Create a test image record directly in the database
      image_attrs = %{
        id: Ecto.UUID.generate(),
        filename: "test-image.jpg",
        file_path: "/uploads/test/test-image.jpg",
        file_url: "/uploads/test/test-image.jpg",
        file_size: 12345,
        content_type: "image/jpeg",
        alt_text: "Test image",
        is_primary: false,
        entity_type: "character",
        entity_id: character_id,
        metadata: %{},
        position_y: 50,
        game_id: game.id,
        user_id: game.owner_id,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
      
      {:ok, image} = GameMasterCore.Repo.insert(struct(GameMasterCore.Images.Image, image_attrs))
      
      {:ok, character_id: character_id, image: image}
    end

    test "updates position_y successfully", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => 25
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      response_data = json_response(conn, 200)["data"]
      assert response_data["position_y"] == 25
      assert response_data["id"] == image.id
    end

    test "updates position_y to 0", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => 0
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      response_data = json_response(conn, 200)["data"]
      assert response_data["position_y"] == 0
    end

    test "updates position_y to 100", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => 100
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      response_data = json_response(conn, 200)["data"]
      assert response_data["position_y"] == 100
    end

    test "rejects position_y below 0", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => -1
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      assert response(conn, 422)
    end

    test "rejects position_y above 100", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => 101
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      assert response(conn, 422)
    end

    test "preserves position_y when not provided", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "alt_text" => "Updated alt text"
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      response_data = json_response(conn, 200)["data"]
      assert response_data["position_y"] == 50  # Should preserve original value
      assert response_data["alt_text"] == "Updated alt text"
    end

    test "updates position_y along with other fields", %{conn: conn, game: game, character_id: character_id, image: image} do
      update_attrs = %{
        "image" => %{
          "position_y" => 75,
          "alt_text" => "New alt text",
          "is_primary" => true
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{image.id}", update_attrs)
      
      response_data = json_response(conn, 200)["data"]
      assert response_data["position_y"] == 75
      assert response_data["alt_text"] == "New alt text"
      assert response_data["is_primary"] == true
    end

    test "returns 404 for non-existent image", %{conn: conn, game: game, character_id: character_id} do
      fake_image_id = Ecto.UUID.generate()
      
      update_attrs = %{
        "image" => %{
          "position_y" => 25
        }
      }
      
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character_id}/images/#{fake_image_id}", update_attrs)
      
      assert response(conn, 404)
    end
  end
end
