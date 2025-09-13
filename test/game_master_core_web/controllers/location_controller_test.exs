defmodule GameMasterCoreWeb.LocationControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.LocationsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures

  alias GameMasterCore.Locations.Location

  @create_attrs %{
    name: "some name",
    type: "city",
    description: "some description"
  }
  @update_attrs %{
    name: "some updated name",
    type: "settlement",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, type: nil, description: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, game: game}
  end

  describe "index" do
    test "lists all locations", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/locations")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to locations for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/locations")
      end
    end
  end

  describe "create location" do
    test "renders location when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/locations", location: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/locations/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "name" => "some name",
               "type" => "city"
             } = json_response(conn, 200)["data"]
    end

    test "denies location creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/locations", location: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/locations", location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update location" do
    setup [:create_location]

    test "renders location when data is valid", %{
      conn: conn,
      location: %Location{id: id} = location,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/locations/#{location}", location: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/locations/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "name" => "some updated name",
               "type" => "settlement"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, location: location, game: game} do
      conn = put(conn, ~p"/api/games/#{game}/locations/#{location}", location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "denies update for locations in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_location = location_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        put(conn, ~p"/api/games/#{other_game.id}/locations/#{other_location.id}",
          location: @update_attrs
        )
      end
    end
  end

  describe "delete location" do
    setup [:create_location]

    test "deletes chosen location", %{conn: conn, location: location, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/locations/#{location}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/locations/#{location}")
      end
    end

    test "denies deletion for locations in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_location = location_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/locations/#{other_location.id}")
      end
    end
  end

  describe "game member access" do
    test "allows game members to access locations", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = get(member_conn, ~p"/api/games/#{game.id}/locations")
      assert json_response(conn, 200)["data"] == []
    end

    test "allows game members to create locations", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = post(member_conn, ~p"/api/games/#{game.id}/locations", location: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  describe "location links" do
    setup [:create_location]

    test "list_links returns location links", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create a link first
      post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["location_id"] == location.id
      assert response["data"]["location_name"] == location.name

      assert [note_response] = response["data"]["links"]["notes"]
      assert note_response["id"] == note.id
      assert note_response["name"] == note.name
      assert note_response["content"] == note.content
      assert note_response["created_at"]
      assert note_response["updated_at"]
    end

    test "list_links returns empty links for location with no links", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["location_id"] == location.id
      assert response["data"]["links"]["notes"] == []
    end

    test "create_link successfully creates location-note link", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["location_id"] == location.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
    end

    test "create_link with missing entity_type returns error", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_id" => note.id
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity type is required"
    end

    test "create_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "invalid",
          "entity_id" => note.id
        })

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "create_link with missing entity_id returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity ID is required"
    end

    test "create_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with non-existent note returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => 999_999
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with cross-scope note returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_note = note_fixture(other_scope, %{game_id: other_game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => other_note.id
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "item",
          "entity_id" => 1
        })

      response = json_response(conn, 422)
      assert response["error"] == "Linking locations to item is not yet supported"
    end

    test "create_link prevents duplicate links", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create first link
      post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Try to create duplicate link
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      assert json_response(conn, 422)["errors"]
    end

    test "delete_link successfully removes location-note link", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Delete the link
      conn =
        delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/note/#{note.id}")

      assert response(conn, 204)
    end

    test "delete_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      location: location,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/note/#{note.id}")

      assert json_response(conn, 404)
    end

    test "delete_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/invalid/1")
      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "delete_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/note/invalid")
      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "delete_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      location: location
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/item/1")
      response = json_response(conn, 422)
      assert response["error"] == "Linking locations to item is not yet supported"
    end

    test "denies access to links for locations in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_location = location_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/locations/#{other_location.id}/links")
      end

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/locations/#{other_location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => 1
        })
      end

      assert_error_sent 404, fn ->
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/locations/#{other_location.id}/links/note/1"
        )
      end
    end
  end

  defp create_location(%{scope: scope, game: game}) do
    location = location_fixture(scope, %{game_id: game.id})

    %{location: location}
  end
end
