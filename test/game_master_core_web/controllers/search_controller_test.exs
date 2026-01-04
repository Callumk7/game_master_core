defmodule GameMasterCoreWeb.SearchControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, game: game}
  end

  describe "search" do
    test "returns 400 when query parameter is missing", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/search")
      assert json_response(conn, 400)["error"] =~ "Query parameter 'q' is required"
    end

    test "returns 400 when query parameter is empty", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/search?q=")
      assert json_response(conn, 400)["error"] =~ "Query parameter 'q' is required"
    end

    test "returns 404 for unauthorized game", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = get(conn, ~p"/api/games/#{other_game.id}/search?q=dragon")
      assert conn.status == 404
    end

    test "returns search results with valid query", %{conn: conn, game: game, scope: scope} do
      # Create test entities
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "A brave hero",
        game_id: game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "A secretive order",
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon")
      response = json_response(conn, 200)["data"]

      assert response["query"] == "dragon"
      assert response["total_results"] == 2
      assert length(response["results"]["characters"]) == 1
      assert length(response["results"]["factions"]) == 1
    end

    test "respects entity_types filter", %{conn: conn, game: game, scope: scope} do
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "hero",
        game_id: game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "order",
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon&types=character")
      response = json_response(conn, 200)["data"]

      assert response["total_results"] == 1
      assert length(response["results"]["characters"]) == 1
      assert length(response["results"]["factions"]) == 0
    end

    test "respects tags filter with AND logic", %{conn: conn, game: game, scope: scope} do
      character_fixture(scope, %{
        name: "Villain",
        content_plain_text: "evil",
        tags: ["npc", "villain"],
        game_id: game.id
      })

      character_fixture(scope, %{
        name: "Hero",
        content_plain_text: "good",
        tags: ["npc", "hero"],
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=ill&tags=npc,villain")
      response = json_response(conn, 200)["data"]

      assert response["total_results"] == 1
      assert hd(response["results"]["characters"])["name"] == "Villain"
    end

    test "respects pinned_only filter", %{conn: conn, game: game, scope: scope} do
      character_fixture(scope, %{
        name: "Dragon King",
        content_plain_text: "ruler",
        pinned: true,
        game_id: game.id
      })

      character_fixture(scope, %{
        name: "Dragon Knight",
        content_plain_text: "warrior",
        pinned: false,
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon&pinned_only=true")
      response = json_response(conn, 200)["data"]

      assert response["total_results"] == 1
      assert response["filters"]["pinned_only"] == true
      assert hd(response["results"]["characters"])["name"] == "Dragon King"
    end

    test "respects limit parameter", %{conn: conn, game: game, scope: scope} do
      for i <- 1..5 do
        character_fixture(scope, %{
          name: "Dragon #{i}",
          content_plain_text: "character #{i}",
          game_id: game.id
        })
      end

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon&limit=2")
      response = json_response(conn, 200)["data"]

      assert response["pagination"]["limit"] == 2
      assert length(response["results"]["characters"]) == 2
    end

    test "respects offset parameter", %{conn: conn, game: game, scope: scope} do
      character_fixture(scope, %{
        name: "Dragon A",
        content_plain_text: "first",
        pinned: false,
        game_id: game.id
      })

      character_fixture(scope, %{
        name: "Dragon B",
        content_plain_text: "second",
        pinned: false,
        game_id: game.id
      })

      character_fixture(scope, %{
        name: "Dragon C",
        content_plain_text: "third",
        pinned: false,
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon&limit=2&offset=2")
      response = json_response(conn, 200)["data"]

      assert response["pagination"]["offset"] == 2
      assert length(response["results"]["characters"]) == 1
    end

    test "returns correct response structure", %{conn: conn, game: game, scope: scope} do
      character_fixture(scope, %{
        name: "Dragon",
        content_plain_text: "test",
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon")
      response = json_response(conn, 200)["data"]

      assert Map.has_key?(response, "query")
      assert Map.has_key?(response, "total_results")
      assert Map.has_key?(response, "filters")
      assert Map.has_key?(response, "pagination")
      assert Map.has_key?(response, "results")

      assert Map.has_key?(response["filters"], "entity_types")
      assert Map.has_key?(response["filters"], "tags")
      assert Map.has_key?(response["filters"], "pinned_only")

      assert Map.has_key?(response["pagination"], "limit")
      assert Map.has_key?(response["pagination"], "offset")

      assert Map.has_key?(response["results"], "characters")
      assert Map.has_key?(response["results"], "factions")
      assert Map.has_key?(response["results"], "locations")
      assert Map.has_key?(response["results"], "quests")
      assert Map.has_key?(response["results"], "notes")
    end

    test "handles multiple entity_types in types parameter", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "hero",
        game_id: game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "order",
        game_id: game.id
      })

      location_fixture(scope, %{
        name: "Dragon's Lair",
        type: "complex",
        content_plain_text: "cave",
        game_id: game.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/search?q=dragon&types=character,faction")
      response = json_response(conn, 200)["data"]

      assert response["total_results"] == 2
      assert length(response["results"]["characters"]) == 1
      assert length(response["results"]["factions"]) == 1
      assert length(response["results"]["locations"]) == 0
    end

    test "returns empty results when no matches found", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/search?q=nonexistent")
      response = json_response(conn, 200)["data"]

      assert response["total_results"] == 0
      assert response["results"]["characters"] == []
      assert response["results"]["factions"] == []
      assert response["results"]["locations"] == []
      assert response["results"]["quests"] == []
      assert response["results"]["notes"] == []
    end
  end
end
