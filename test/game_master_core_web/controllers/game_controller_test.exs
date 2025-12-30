defmodule GameMasterCoreWeb.GameControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures
  alias GameMasterCore.Games.Game

  # Import additional fixtures for entities
  alias GameMasterCore.CharactersFixtures
  alias GameMasterCore.NotesFixtures
  alias GameMasterCore.FactionsFixtures
  alias GameMasterCore.LocationsFixtures
  alias GameMasterCore.QuestsFixtures

  @create_attrs %{
    name: "some name",
    content: "some content",
    setting: "some setting"
  }
  @update_attrs %{
    name: "some updated name",
    content: "some updated content",
    setting: "some updated setting"
  }
  @invalid_attrs %{name: nil, content: nil, setting: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user} do
    conn = authenticate_api_user(conn, user)
    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all games", %{conn: conn} do
      conn = get(conn, ~p"/api/games")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create game" do
    test "renders game when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/games", game: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name",
               "setting" => "some setting"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/games", game: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update game" do
    setup [:create_game]

    test "renders game when data is valid", %{conn: conn, game: %Game{id: id} = game} do
      conn = put(conn, ~p"/api/games/#{game}", game: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name",
               "setting" => "some updated setting"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game}", game: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete game" do
    setup [:create_game]

    test "deletes chosen game", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game}")
      assert json_response(conn, 404)
    end
  end

  describe "list_entities with fields parameter" do
    setup [:create_game_with_entities]

    test "returns all fields when fields=all", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=all")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Check that a character has all expected fields
      character = List.first(entities["characters"])
      assert character["id"]
      assert character["name"]
      assert character["game_id"]
      assert character["content"]
      assert character["content_plain_text"]
      assert character["class"]
      assert character["level"]
      assert character["tags"]
      assert character["created_at"]
      assert character["updated_at"]
    end

    test "returns minimal fields when fields=minimal", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=minimal")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Check that a character has only minimal fields
      character = List.first(entities["characters"])
      assert character["id"]
      assert character["name"]
      assert character["game_id"]
      assert character["class"]
      assert character["level"]
      # These fields should NOT be present
      refute Map.has_key?(character, "content")
      refute Map.has_key?(character, "content_plain_text")
      refute Map.has_key?(character, "tags")
      refute Map.has_key?(character, "created_at")
      refute Map.has_key?(character, "updated_at")

      # Check that a note has only minimal fields (no entity-specific required fields)
      note = List.first(entities["notes"])
      assert note["id"]
      assert note["name"]
      assert note["game_id"]
      refute Map.has_key?(note, "content")
      refute Map.has_key?(note, "content_plain_text")
    end

    test "returns plain_text fields when fields=plain_text", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=plain_text")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Check that a character has plain_text fields
      character = List.first(entities["characters"])
      assert character["id"]
      assert character["name"]
      assert character["game_id"]
      assert character["content_plain_text"]
      assert character["class"]
      assert character["level"]
      # These fields should NOT be present
      refute Map.has_key?(character, "content")
      refute Map.has_key?(character, "tags")
      refute Map.has_key?(character, "created_at")
      refute Map.has_key?(character, "updated_at")
    end

    test "defaults to all fields when fields parameter is missing", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Check that a character has all expected fields (default behavior)
      character = List.first(entities["characters"])
      assert character["content"]
      assert character["content_plain_text"]
      assert character["tags"]
      assert character["created_at"]
    end

    test "defaults to all fields when fields parameter is invalid", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=invalid_value")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Check that a character has all expected fields (fallback to default)
      character = List.first(entities["characters"])
      assert character["content"]
      assert character["content_plain_text"]
      assert character["tags"]
      assert character["created_at"]
    end

    test "minimal fields works for all entity types", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=minimal")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Verify each entity type has minimal fields
      character = List.first(entities["characters"])
      assert character["id"] && character["name"] && character["class"] && character["level"]
      refute Map.has_key?(character, "content")

      note = List.first(entities["notes"])
      assert note["id"] && note["name"] && note["game_id"]
      refute Map.has_key?(note, "content")

      faction = List.first(entities["factions"])
      assert faction["id"] && faction["name"] && faction["game_id"]
      refute Map.has_key?(faction, "content")

      location = List.first(entities["locations"])
      assert location["id"] && location["name"] && location["type"]
      refute Map.has_key?(location, "content")

      quest = List.first(entities["quests"])
      assert quest["id"] && quest["name"] && quest["status"]
      refute Map.has_key?(quest, "content")
    end

    test "plain_text fields works for all entity types", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/links?fields=plain_text")
      response = json_response(conn, 200)

      assert %{"data" => %{"entities" => entities}} = response

      # Verify each entity type has plain_text fields
      character = List.first(entities["characters"])
      assert character["content_plain_text"]
      refute Map.has_key?(character, "content")
      refute Map.has_key?(character, "tags")

      note = List.first(entities["notes"])
      assert note["content_plain_text"]
      refute Map.has_key?(note, "content")

      faction = List.first(entities["factions"])
      assert faction["content_plain_text"]
      refute Map.has_key?(faction, "content")

      location = List.first(entities["locations"])
      assert location["content_plain_text"]
      refute Map.has_key?(location, "content")

      quest = List.first(entities["quests"])
      assert quest["content_plain_text"]
      refute Map.has_key?(quest, "content")
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid game id format", %{conn: conn} do
      conn = put(conn, ~p"/api/games/invalid", game: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/api/games/#{non_existent_id}", game: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/api/games/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "add_member returns 404 for invalid game id format", %{conn: conn} do
      conn = post(conn, ~p"/api/games/invalid/members", %{"user_id" => "123", "role" => "member"})
      assert json_response(conn, 404)
    end

    test "add_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{non_existent_id}/members", %{
          "user_id" => "123",
          "role" => "member"
        })

      assert json_response(conn, 404)
    end

    test "remove_member returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/api/games/invalid/members/123")
      assert json_response(conn, 404)
    end

    test "remove_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{non_existent_id}/members/123")
      assert json_response(conn, 404)
    end

    test "list_members returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid/members")
      assert json_response(conn, 404)
    end

    test "list_members returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}/members")
      assert json_response(conn, 404)
    end

    test "list_entities returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_entities returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end
  end

  defp create_game(%{scope: scope}) do
    game = game_fixture(scope)

    %{game: game}
  end

  defp create_game_with_entities(%{scope: scope}) do
    game = game_fixture(scope)

    # Create a scope with the game for entities that need it (like quests)
    scope_with_game = GameMasterCore.Accounts.Scope.put_game(scope, game)

    # Create one entity of each type with the same game_id
    character =
      CharactersFixtures.character_fixture(scope_with_game, %{
        game_id: game.id,
        name: "Test Character",
        content: "<p>Test character content</p>",
        content_plain_text: "Test character content",
        class: "Warrior",
        level: 5,
        tags: ["test", "character"]
      })

    note =
      NotesFixtures.note_fixture(scope_with_game, %{
        game_id: game.id,
        name: "Test Note",
        content: "<p>Test note content</p>",
        content_plain_text: "Test note content",
        tags: ["test", "note"]
      })

    faction =
      FactionsFixtures.faction_fixture(scope_with_game, %{
        game_id: game.id,
        name: "Test Faction",
        content: "<p>Test faction content</p>",
        content_plain_text: "Test faction content",
        tags: ["test", "faction"]
      })

    location =
      LocationsFixtures.location_fixture(scope_with_game, %{
        game_id: game.id,
        name: "Test Location",
        content: "<p>Test location content</p>",
        content_plain_text: "Test location content",
        type: "city",
        tags: ["test", "location"]
      })

    quest =
      QuestsFixtures.quest_fixture(scope_with_game, %{
        game_id: game.id,
        name: "Test Quest",
        content: "<p>Test quest content</p>",
        content_plain_text: "Test quest content",
        status: "active",
        tags: ["test", "quest"]
      })

    %{
      game: game,
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    }
  end
end
