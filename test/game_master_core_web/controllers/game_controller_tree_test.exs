defmodule GameMasterCoreWeb.GameControllerTreeTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures

  alias GameMasterCore.{Characters, Factions, Links}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user} do
    conn = authenticate_api_user(conn, user)
    {:ok, conn: conn}
  end

  describe "GET /api/games/:id/tree" do
    setup %{conn: conn, user: user} do
      user_scope = GameMasterCore.Accounts.Scope.for_user(user)
      game = game_fixture(user_scope)
      scope = GameMasterCore.Accounts.Scope.put_game(user_scope, game)

      %{conn: conn, game: game, scope: scope}
    end

    test "returns empty tree for game with no entities", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/tree")
      
      assert %{
        "data" => %{
          "characters" => [],
          "factions" => [],
          "locations" => [],
          "quests" => [],
          "notes" => []
        }
      } = json_response(conn, 200)
    end

    test "returns tree with entities and relationships", %{conn: conn, game: game, scope: scope} do
      # Create entities
      {:ok, character} = Characters.create_character_for_game(scope, %{
        name: "Test Character",
        class: "Warrior",
        level: 1,
        content: "A test character"
      })

      {:ok, faction} = Factions.create_faction_for_game(scope, %{
        name: "Test Faction",
        content: "A test faction"
      })

      # Create link
      {:ok, _link} = Links.link(character, faction, %{
        relationship_type: "member",
        description: "Character is a member",
        strength: 8
      })

      conn = get(conn, ~p"/api/games/#{game.id}/tree")
      response = json_response(conn, 200)
      
      assert %{"data" => data} = response
      assert %{"characters" => [char_data]} = data
      
      assert char_data["id"] == character.id
      assert char_data["name"] == "Test Character"
      assert char_data["type"] == "character"
      
      # Check linked faction
      assert [faction_data] = char_data["children"]
      assert faction_data["id"] == faction.id
      assert faction_data["name"] == "Test Faction"
      assert faction_data["type"] == "faction"
      assert faction_data["relationship_type"] == "member"
      assert faction_data["description"] == "Character is a member"
      assert faction_data["strength"] == 8
    end

    test "respects depth parameter", %{conn: conn, game: game, scope: scope} do
      # Create entities
      {:ok, character} = Characters.create_character_for_game(scope, %{
        name: "Character", class: "Warrior", level: 1, content: "Test"
      })
      {:ok, faction} = Factions.create_faction_for_game(scope, %{
        name: "Faction", content: "Test"
      })

      {:ok, _} = Links.link(character, faction)

      # Test depth=1
      conn = get(conn, ~p"/api/games/#{game.id}/tree?depth=1")
      response = json_response(conn, 200)
      
      char_data = hd(response["data"]["characters"])
      assert length(char_data["children"]) == 1
      faction_data = hd(char_data["children"])
      assert faction_data["children"] == []
    end

    test "returns error for invalid depth", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/tree?depth=invalid")
      
      assert %{"error" => "Invalid depth parameter. Must be an integer between 1 and 10."} = 
        json_response(conn, 400)
    end

    test "returns error for depth out of range", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/tree?depth=15")
      
      assert %{"error" => "Invalid depth parameter. Must be an integer between 1 and 10."} = 
        json_response(conn, 400)
    end

    test "returns 404 for non-existent game", %{conn: conn} do
      fake_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{fake_id}/tree")
      
      assert json_response(conn, 404)
    end
  end
end