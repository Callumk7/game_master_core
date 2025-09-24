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
    content: "some content"
  }
  @update_attrs %{
    name: "some updated name",
    type: "settlement",
    content: "some updated content"
  }
  @invalid_attrs %{name: nil, type: nil, content: nil}

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
               "content" => "some content",
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
               "content" => "some updated content",
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

      conn = get(conn, ~p"/api/games/#{game}/locations/#{location}")
      assert json_response(conn, 404)
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
      non_existent_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => non_existent_uuid
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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links", %{
          "entity_type" => "item",
          "entity_id" => dummy_uuid
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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/locations/#{location.id}/links/invalid/#{dummy_uuid}"
        )

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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(conn, ~p"/api/games/#{game.id}/locations/#{location.id}/links/item/#{dummy_uuid}")

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
        dummy_uuid = Ecto.UUID.generate()

        post(conn, ~p"/api/games/#{other_game.id}/locations/#{other_location.id}/links", %{
          "entity_type" => "note",
          "entity_id" => dummy_uuid
        })
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        delete(
          conn,
          ~p"/api/games/#{other_game.id}/locations/#{other_location.id}/links/note/#{dummy_uuid}"
        )
      end
    end
  end

  describe "location tree" do
    test "returns empty tree when no locations exist", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "returns flat tree structure for single level locations", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Create two root locations
      location1 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Forest",
          type: "region",
          parent_id: nil
        })

      location2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Mountains",
          type: "region",
          parent_id: nil
        })

      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 2

      # Should be sorted by name
      [first, second] = response["data"]
      assert first["name"] == "Forest"
      assert first["id"] == location1.id
      assert first["children"] == []

      assert second["name"] == "Mountains"
      assert second["id"] == location2.id
      assert second["children"] == []
    end

    test "returns hierarchical tree structure with parent-child relationships", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Create continent (root)
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Westeros",
          type: "continent",
          parent_id: nil
        })

      # Create nation (child of continent)
      nation =
        location_fixture(scope, %{
          game_id: game.id,
          name: "The North",
          type: "nation",
          parent_id: continent.id
        })

      # Create city (child of nation)
      city =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Winterfell",
          type: "city",
          parent_id: nation.id
        })

      # Create another city in the same nation
      city2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Deepwood Motte",
          type: "city",
          parent_id: nation.id
        })

      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1

      # Check continent level
      [continent_data] = response["data"]
      assert continent_data["name"] == "Westeros"
      assert continent_data["id"] == continent.id
      assert continent_data["type"] == "continent"
      assert continent_data["parent_id"] == nil

      # Check nation level
      assert length(continent_data["children"]) == 1
      [nation_data] = continent_data["children"]
      assert nation_data["name"] == "The North"
      assert nation_data["id"] == nation.id
      assert nation_data["type"] == "nation"
      assert nation_data["parent_id"] == continent.id

      # Check city level (should be sorted by name)
      assert length(nation_data["children"]) == 2
      [city1_data, city2_data] = nation_data["children"]
      assert city1_data["name"] == "Deepwood Motte"
      assert city1_data["id"] == city2.id
      assert city1_data["children"] == []

      assert city2_data["name"] == "Winterfell"
      assert city2_data["id"] == city.id
      assert city2_data["children"] == []
    end

    test "includes all location fields in tree response", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      location =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Test Location",
          content: "A test location",
          type: "city",
          tags: ["test", "example"],
          parent_id: nil
        })

      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      [location_data] = response["data"]
      assert location_data["id"] == location.id
      assert location_data["name"] == "Test Location"
      assert location_data["content"] == "A test location"
      assert location_data["type"] == "city"
      assert location_data["tags"] == ["test", "example"]
      assert location_data["parent_id"] == nil
      assert location_data["entity_type"] == "location"
      assert location_data["children"] == []
    end

    test "handles deep nesting correctly", %{conn: conn, game: game, scope: scope} do
      # Create a 4-level hierarchy
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Continent",
          type: "continent",
          parent_id: nil
        })

      nation =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Nation",
          type: "nation",
          parent_id: continent.id
        })

      region =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Region",
          type: "region",
          parent_id: nation.id
        })

      _city =
        location_fixture(scope, %{
          game_id: game.id,
          name: "City",
          type: "city",
          parent_id: region.id
        })

      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      [continent_data] = response["data"]
      [nation_data] = continent_data["children"]
      [region_data] = nation_data["children"]
      [city_data] = region_data["children"]

      assert continent_data["name"] == "Continent"
      assert nation_data["name"] == "Nation"
      assert region_data["name"] == "Region"
      assert city_data["name"] == "City"
      assert city_data["children"] == []
    end

    test "only returns locations for the specified game", %{conn: conn, game: game, scope: scope} do
      # Create location in this game
      _our_location =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Our Location",
          type: "city"
        })

      # Create another game and location
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)

      _other_location =
        location_fixture(other_scope, %{
          game_id: other_game.id,
          name: "Other Location",
          type: "city"
        })

      conn = get(conn, ~p"/api/games/#{game}/locations/tree")
      response = json_response(conn, 200)

      # Should only return our location
      assert length(response["data"]) == 1
      [location_data] = response["data"]
      assert location_data["name"] == "Our Location"
    end

    test "denies access to tree for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/locations/tree")
      end
    end

    test "allows game members to access location tree", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Create a location
      _location =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Member Location",
          type: "city"
        })

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = get(member_conn, ~p"/api/games/#{game.id}/locations/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      [location_data] = response["data"]
      assert location_data["name"] == "Member Location"
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/locations/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/locations/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game.id}/locations/invalid", location: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        put(conn, ~p"/api/games/#{game.id}/locations/#{non_existent_id}",
          location: %{name: "test"}
        )

      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game.id}/locations/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/locations/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/locations/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/locations/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end

    test "create_link returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/invalid/links", %{
          "entity_type" => "note",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "create_link returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/locations/#{non_existent_id}/links", %{
          "entity_type" => "note",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for invalid location id format", %{conn: conn, game: game} do
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/locations/invalid/links/note/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for non-existent location", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/locations/#{non_existent_id}/links/note/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end
  end

  defp create_location(%{scope: scope, game: game}) do
    location = location_fixture(scope, %{game_id: game.id})

    %{location: location}
  end
end
