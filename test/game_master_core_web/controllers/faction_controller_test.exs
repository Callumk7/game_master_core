defmodule GameMasterCoreWeb.FactionControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.FactionsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures
  alias GameMasterCore.Factions.Faction

  @create_attrs %{
    name: "some name",
    description: "some description"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    user_token = GameMasterCore.Accounts.create_user_api_token(user)
    game = game_fixture(scope)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user_token}")

    {:ok, conn: conn, game: game}
  end

  describe "index" do
    test "lists all factions", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/factions")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to factions for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/factions")
      end
    end
  end

  describe "create faction" do
    test "renders faction when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/factions", faction: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/factions/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies faction creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/factions", faction: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/factions", faction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update faction" do
    setup [:create_faction]

    test "renders faction when data is valid", %{
      conn: conn,
      faction: %Faction{id: id} = faction,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/factions/#{faction}", faction: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/factions/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      faction: faction,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/factions/#{faction}", faction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete faction" do
    setup [:create_faction]

    test "deletes chosen faction", %{conn: conn, faction: faction, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/factions/#{faction}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/factions/#{faction}")
      end
    end

    test "denies deletion for factions in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_faction = faction_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}")
      end
    end
  end

  describe "faction links" do
    setup [:create_faction]

    test "list_links returns faction links", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create a link first
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name

      assert response["data"]["links"]["notes"] == [
               %{
                 "id" => note.id,
                 "name" => note.name,
                 "content" => note.content
               }
             ]
    end

    test "list_links returns empty links for faction with no links", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["links"]["notes"] == []
    end

    test "create_link successfully creates faction-note link", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
    end

    test "create_link with missing entity_type returns error", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_id" => note.id
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity type is required"
    end

    test "create_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "invalid",
          "entity_id" => note.id
        })

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, item, location, quest"
    end

    test "create_link with missing entity_id returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity ID is required"
    end

    test "create_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with non-existent note returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => 999_999
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with cross-scope note returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_note = note_fixture(other_scope, %{game_id: other_game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => other_note.id
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "item",
          "entity_id" => 1
        })

      response = json_response(conn, 422)
      assert response["error"] == "Linking factions to item is not yet supported"
    end

    test "create_link prevents duplicate links", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create first link
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Try to create duplicate link
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      assert json_response(conn, 422)["errors"]
    end

    test "delete_link successfully removes faction-note link", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Delete the link
      conn =
        delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/#{note.id}")

      assert response(conn, 204)
    end

    test "delete_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/#{note.id}")

      assert json_response(conn, 404)
    end

    test "delete_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/invalid/1")
      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, item, location, quest"
    end

    test "delete_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/invalid")
      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "delete_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/item/1")
      response = json_response(conn, 422)
      assert response["error"] == "Linking factions to item is not yet supported"
    end

    test "denies access to links for factions in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_faction = faction_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links")
      end

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => 1
        })
      end

      assert_error_sent 404, fn ->
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links/note/1"
        )
      end
    end
  end

  defp create_faction(%{scope: scope, game: game}) do
    faction = faction_fixture(scope, %{game_id: game.id})

    %{faction: faction}
  end
end
