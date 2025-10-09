defmodule GameMasterCoreWeb.FactionControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.FactionsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.LocationsFixtures
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

      conn = get(conn, ~p"/api/games/#{other_game.id}/factions")
      assert conn.status == 404
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

      conn = post(conn, ~p"/api/games/#{other_game.id}/factions", faction: @create_attrs)
      assert conn.status == 404
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

      conn = delete(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}")
      assert conn.status == 404
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

      conn = get(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links")
      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links", %{
          "entity_type" => "note",
          "entity_id" => dummy_uuid
        })

      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links/note/#{dummy_uuid}"
        )

      assert conn.status == 404
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

      conn = get(conn, ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/members")
      assert conn.status == 404
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

  describe "update_link" do
    setup [:create_faction]

    test "update_link successfully updates faction-note link metadata", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # First create a link
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id,
        "relationship_type" => "documented",
        "description" => "Initial documentation",
        "strength" => 5
      })

      # Then update the link
      conn =
        put(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/#{note.id}", %{
          "relationship_type" => "secret",
          "description" => "Updated to secret information",
          "strength" => 8
        })

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
      assert response["updated_at"]
    end

    test "update_link successfully updates faction-character link metadata", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # First create a link
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id,
        "relationship_type" => "member",
        "strength" => 7
      })

      # Then update the link
      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/factions/#{faction.id}/links/character/#{character.id}",
          %{
            "relationship_type" => "leader",
            "description" => "Promoted to leader",
            "strength" => 10
          }
        )

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "character"
      assert response["entity_id"] == character.id
    end

    test "update_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Try to update a link that doesn't exist
      conn =
        put(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/#{note.id}", %{
          "relationship_type" => "secret",
          "description" => "Should fail",
          "strength" => 8
        })

      assert json_response(conn, 404)
    end

    test "update_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/factions/#{faction.id}/links/invalid_type/#{dummy_uuid}",
          %{
            "relationship_type" => "ally"
          }
        )

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "update_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn =
        put(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links/note/invalid_id", %{
          "relationship_type" => "ally"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "denies access to update_link for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_faction = faction_fixture(other_user_scope, %{game_id: other_game.id})
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      conn =
        put(
          conn,
          ~p"/api/games/#{other_game.id}/factions/#{other_faction.id}/links/note/#{other_note.id}",
          %{
            "relationship_type" => "ally"
          }
        )

      assert response(conn, 404)
    end
  end

  describe "faction notes tree" do
    setup [:create_faction]

    test "notes_tree returns empty tree for faction with no notes", %{
      conn: conn,
      game: game,
      faction: faction
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/notes/tree")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name
      assert response["data"]["notes_tree"] == []
    end

    test "notes_tree returns direct child notes", %{
      conn: conn,
      scope: scope,
      game: game,
      faction: faction
    } do
      # Create notes attached to faction
      _note1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Faction Note 1",
          content: "Content 1",
          parent_id: faction.id,
          parent_type: "faction"
        })

      _note2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Faction Note 2",
          content: "Content 2",
          parent_id: faction.id,
          parent_type: "faction"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/notes/tree")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert response["data"]["faction_name"] == faction.name

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 2

      # Verify note structure (should be sorted alphabetically)
      [first_note, second_note] = notes_tree

      assert first_note["name"] == "Faction Note 1"
      assert first_note["content"] == "Content 1"
      assert first_note["parent_id"] == faction.id
      assert first_note["parent_type"] == "faction"
      assert first_note["children"] == []

      assert second_note["name"] == "Faction Note 2"
      assert second_note["content"] == "Content 2"
      assert second_note["children"] == []
    end

    test "notes_tree returns hierarchical structure with note children", %{
      conn: conn,
      scope: scope,
      game: game,
      faction: faction
    } do
      # Create root note attached to faction
      root_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Root Note",
          content: "Root content",
          parent_id: faction.id,
          parent_type: "faction"
        })

      # Create child note (traditional note hierarchy)
      child_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child Note",
          content: "Child content",
          parent_id: root_note.id
          # parent_type is nil for traditional note hierarchy
        })

      # Create grandchild note
      _grandchild_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Grandchild Note",
          content: "Grandchild content",
          parent_id: child_note.id
        })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/notes/tree")
      response = json_response(conn, 200)

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 1

      # Check root note
      root = hd(notes_tree)
      assert root["name"] == "Root Note"
      assert root["id"] == root_note.id
      assert root["parent_id"] == faction.id
      assert root["parent_type"] == "faction"

      # Check child structure
      children = root["children"]
      assert length(children) == 1

      child = hd(children)
      assert child["name"] == "Child Note"
      assert child["id"] == child_note.id

      # Check grandchild structure
      grandchildren = child["children"]
      assert length(grandchildren) == 1

      grandchild = hd(grandchildren)
      assert grandchild["name"] == "Grandchild Note"
      assert grandchild["children"] == []
    end

    test "notes_tree excludes notes from other factions and games", %{
      conn: conn,
      scope: scope,
      game: game,
      faction: faction
    } do
      # Create note for this faction
      _faction_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "My Faction Note",
          parent_id: faction.id,
          parent_type: "faction"
        })

      # Create another faction in the same game
      other_faction = faction_fixture(scope, %{game_id: game.id})

      _other_faction_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Other Faction Note",
          parent_id: other_faction.id,
          parent_type: "faction"
        })

      # Create a note in a different game
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_game_faction = faction_fixture(other_scope, %{game_id: other_game.id})

      _other_game_note =
        note_fixture(other_scope, %{
          game_id: other_game.id,
          name: "Other Game Note",
          parent_id: other_game_faction.id,
          parent_type: "faction"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/notes/tree")
      response = json_response(conn, 200)

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 1
      assert hd(notes_tree)["name"] == "My Faction Note"
    end

    test "notes_tree returns 404 for non-existent faction", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{non_existent_id}/notes/tree")
      assert json_response(conn, 404)
    end

    test "notes_tree returns 404 for invalid faction id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/factions/invalid/notes/tree")
      assert json_response(conn, 404)
    end

    test "notes_tree requires authentication", %{game: game, faction: faction} do
      conn = build_conn()
      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/notes/tree")
      assert response(conn, 401)
    end

    test "notes_tree respects game access permissions", %{
      conn: conn,
      faction: faction
    } do
      # Try to access faction from a different game
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)

      conn = get(conn, ~p"/api/games/#{other_game.id}/factions/#{faction.id}/notes/tree")
      assert response(conn, 404)
    end
  end

  defp create_faction(%{scope: scope, game: game}) do
    faction = faction_fixture(scope, %{game_id: game.id})

    %{faction: faction}
  end

  describe "faction links with is_current_location metadata" do
    setup [:create_faction]

    test "create_link successfully creates faction-location link with is_current_location metadata",
         %{
           conn: conn,
           game: game,
           faction: faction,
           scope: scope
         } do
      location = location_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
          "entity_type" => "location",
          "entity_id" => location.id,
          "is_current_location" => true,
          "description" => "Main headquarters",
          "strength" => 10
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "update_link successfully updates faction-location link with is_current_location metadata",
         %{
           conn: conn,
           game: game,
           faction: faction,
           scope: scope
         } do
      location = location_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location.id,
        "is_current_location" => false
      })

      # Update the link with new metadata
      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/factions/#{faction.id}/links/location/#{location.id}",
          %{
            "is_current_location" => true,
            "description" => "Now main headquarters",
            "strength" => 10
          }
        )

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["faction_id"] == faction.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "list_links returns faction links with is_current_location metadata", %{
      conn: conn,
      game: game,
      faction: faction,
      scope: scope
    } do
      location1 = location_fixture(scope, %{game_id: game.id, name: "Current HQ"})
      location2 = location_fixture(scope, %{game_id: game.id, name: "Former HQ"})

      # Create links with different is_current_location values
      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location1.id,
        "is_current_location" => true,
        "description" => "Main headquarters"
      })

      post(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location2.id,
        "is_current_location" => false,
        "description" => "Former headquarters"
      })

      conn = get(conn, ~p"/api/games/#{game.id}/factions/#{faction.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["faction_id"] == faction.id
      assert length(response["data"]["links"]["locations"]) == 2

      locations = response["data"]["links"]["locations"]
      current_location = Enum.find(locations, fn loc -> loc["name"] == "Current HQ" end)
      former_location = Enum.find(locations, fn loc -> loc["name"] == "Former HQ" end)

      assert current_location["is_current_location"] == true
      assert current_location["description_meta"] == "Main headquarters"

      assert former_location["is_current_location"] == false
      assert former_location["description_meta"] == "Former headquarters"
    end
  end
end
