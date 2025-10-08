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
end
