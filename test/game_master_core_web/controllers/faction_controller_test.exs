defmodule GameMasterCoreWeb.FactionControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.FactionsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.CharactersFixtures
  alias GameMasterCore.Factions.Faction

  @create_attrs %{
    name: "some name",
    content: "some content"
  }
  @update_attrs %{
    name: "some updated name",
    content: "some updated content"
  }
  @invalid_attrs %{name: nil, content: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

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
               "content" => "some content",
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
               "content" => "some updated content",
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

      conn = get(conn, ~p"/api/games/#{game}/factions/#{faction}")
      assert json_response(conn, 404)
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

      assert [note_response] = response["data"]["links"]["notes"]
      assert note_response["id"] == note.id
      assert note_response["name"] == note.name
      assert note_response["content"] == note.content
      assert note_response["created_at"]
      assert note_response["updated_at"]
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
               "Invalid entity type. Supported types: note, character, faction, location, quest"
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
      non_existent_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => non_existent_uuid
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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "item",
          "entity_id" => dummy_uuid
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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/invalid/#{dummy_uuid}")

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
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
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/item/#{dummy_uuid}")

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
        dummy_uuid = Ecto.UUID.generate()

        post(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => dummy_uuid
        })
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        delete(
          conn,
          ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links/note/#{dummy_uuid}"
        )
      end
    end

    test "create_link successfully creates faction-faction link", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      other_faction = faction_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "faction",
          "entity_id" => other_faction.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "faction"
      assert response["entity_id"] == other_faction.id
    end

    test "list_links includes faction-faction links", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      other_faction = faction_fixture(scope, %{game_id: game.id})

      # Create a faction-faction link first
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "faction",
        "entity_id" => other_faction.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name
      assert [faction_response] = response["data"]["links"]["factions"]
      assert faction_response["id"] == other_faction.id
      assert faction_response["name"] == other_faction.name
    end
  end

  describe "faction members" do
    setup [:create_faction]

    test "members returns characters that are members of the faction", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      # Create characters with different faction membership statuses
      _member_character1 =
        character_fixture(scope, %{
          game_id: game.id,
          name: "Faction Member 1",
          member_of_faction_id: faction.id,
          faction_role: "Leader"
        })

      _member_character2 =
        character_fixture(scope, %{
          game_id: game.id,
          name: "Faction Member 2",
          member_of_faction_id: faction.id,
          faction_role: "Member"
        })

      # Character without faction membership
      _independent_character =
        character_fixture(scope, %{
          game_id: game.id,
          name: "Independent Character"
        })

      # Character belonging to different faction
      other_faction = faction_fixture(scope, %{game_id: game.id})

      _other_faction_member =
        character_fixture(scope, %{
          game_id: game.id,
          name: "Other Faction Member",
          member_of_faction_id: other_faction.id,
          faction_role: "Scout"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/members")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name
      assert length(response["data"]["members"]) == 2

      member_names = Enum.map(response["data"]["members"], & &1["name"])
      assert "Faction Member 1" in member_names
      assert "Faction Member 2" in member_names
      refute "Independent Character" in member_names
      refute "Other Faction Member" in member_names

      # Verify faction membership fields are included
      leader = Enum.find(response["data"]["members"], &(&1["name"] == "Faction Member 1"))
      assert leader["member_of_faction_id"] == faction.id
      assert leader["faction_role"] == "Leader"

      member = Enum.find(response["data"]["members"], &(&1["name"] == "Faction Member 2"))
      assert member["member_of_faction_id"] == faction.id
      assert member["faction_role"] == "Member"
    end

    test "members returns empty list for faction with no members", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/members")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name
      assert response["data"]["members"] == []
    end

    test "members returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}/members")
      assert json_response(conn, 404)
    end

    test "members returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/invalid/members")
      assert json_response(conn, 404)
    end

    test "members denies access for factions in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_faction = faction_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/members")
      end
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game.id}/factions/invalid", faction: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        put(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}", faction: %{name: "test"})

      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game.id}/factions/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end

    test "create_link returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/invalid/links", %{
          "entity_type" => "note",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "create_link returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}/links", %{
          "entity_type" => "note",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/factions/invalid/links/note/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/factions/#{non_existent_id}/links/note/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end
  end

  defp create_faction(%{scope: scope, game: game}) do
    faction = faction_fixture(scope, %{game_id: game.id})

    %{faction: faction}
  end
end
