defmodule GameMasterCoreWeb.NoteControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.NotesFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.CharactersFixtures
  alias GameMasterCore.Notes.Note

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
    test "lists notes for a game that user owns", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to notes for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = get(conn, ~p"/api/games/#{other_game.id}/notes")
      assert conn.status == 404
    end
  end

  describe "create note" do
    test "renders note when data is valid for owned game", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game.id}/notes", note: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies note creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = post(conn, ~p"/api/games/#{other_game.id}/notes", note: @create_attrs)
      assert conn.status == 404
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game.id}/notes", note: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update note" do
    setup [:create_note]

    test "renders note when data is valid", %{conn: conn, game: game, note: %Note{id: id} = note} do
      conn = put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}", note: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "denies update for notes in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      conn =
        put(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}", note: @update_attrs)

      assert conn.status == 404
    end

    test "renders errors when data is invalid", %{conn: conn, game: game, note: note} do
      conn = put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}", note: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete note" do
    setup [:create_note]

    test "deletes chosen note", %{conn: conn, game: game, note: note} do
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}")
      assert json_response(conn, 404)
    end

    test "denies deletion for notes in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      conn = delete(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}")
      assert conn.status == 404
    end
  end

  describe "game member access" do
    test "allows game members to access notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = get(member_conn, ~p"/api/games/#{game.id}/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "allows game members to create notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = post(member_conn, ~p"/api/games/#{game.id}/notes", note: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  describe "note links" do
    setup [:create_note]

    test "list_links returns note links", %{conn: conn, game: game, note: note, scope: scope} do
      character = character_fixture(scope, %{game_id: game.id})

      # Create a link first
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["note_id"] == note.id
      assert response["data"]["note_name"] == note.name

      assert [character_response] = response["data"]["links"]["characters"]
      assert character_response["id"] == character.id
      assert character_response["name"] == character.name
      assert character_response["level"] == character.level
      assert character_response["class"] == character.class
      assert character_response["created_at"]
      assert character_response["updated_at"]
    end

    test "list_links returns empty links for note with no links", %{
      conn: conn,
      game: game,
      note: note
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["note_id"] == note.id
      assert response["data"]["links"]["characters"] == []
    end

    test "create_link successfully creates note-character link", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => character.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["note_id"] == note.id
      assert response["entity_type"] == "character"
      assert response["entity_id"] == character.id
    end

    test "update_link successfully updates note-character link metadata", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # First create a link
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id,
        "relationship_type" => "ally",
        "description" => "Initial relationship",
        "strength" => 5
      })

      # Then update the link
      conn =
        put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/#{character.id}", %{
          "relationship_type" => "enemy",
          "description" => "Updated relationship",
          "strength" => 8,
          "is_active" => false
        })

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["note_id"] == note.id
      assert response["entity_type"] == "character"
      assert response["entity_id"] == character.id
      assert response["updated_at"]
    end

    test "update_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Try to update a link that doesn't exist
      conn =
        put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/#{character.id}", %{
          "relationship_type" => "enemy",
          "description" => "Should fail",
          "strength" => 8
        })

      assert json_response(conn, 404)
    end

    test "update_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/invalid_type/#{dummy_uuid}", %{
          "relationship_type" => "ally"
        })

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "update_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      conn =
        put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/invalid_id", %{
          "relationship_type" => "ally"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with missing entity_type returns error", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_id" => character.id
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity type is required"
    end

    test "create_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "invalid",
          "entity_id" => character.id
        })

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "create_link with missing entity_id returns error", %{conn: conn, game: game, note: note} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity ID is required"
    end

    test "create_link with invalid entity_id returns error", %{conn: conn, game: game, note: note} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with non-existent character returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      non_existent_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => non_existent_uuid
        })

      response = json_response(conn, 404)
      assert response["error"] == "Character not found"
    end

    test "create_link with cross-scope character returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_character = character_fixture(other_scope, %{game_id: other_game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => other_character.id
        })

      response = json_response(conn, 404)
      assert response["error"] == "Character not found"
    end

    test "create_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "item",
          "entity_id" => dummy_uuid
        })

      response = json_response(conn, 422)
      assert response["error"] == "Linking notes to item is not yet supported"
    end

    test "create_link prevents duplicate links", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Create first link
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      # Try to create duplicate link
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => character.id
        })

      assert json_response(conn, 422)["errors"]
    end

    test "delete_link successfully removes note-character link", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      # Delete the link
      conn =
        delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/#{character.id}")

      assert response(conn, 204)
    end

    test "delete_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/#{character.id}")

      assert json_response(conn, 404)
    end

    test "delete_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      dummy_uuid = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/invalid/#{dummy_uuid}")
      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "delete_link with invalid entity_id returns error", %{conn: conn, game: game, note: note} do
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/character/invalid")
      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "delete_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      note: note
    } do
      dummy_uuid = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/item/#{dummy_uuid}")
      response = json_response(conn, 422)
      assert response["error"] == "Linking notes to item is not yet supported"
    end

    test "denies access to links for notes in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      conn = get(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links")
      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => dummy_uuid
        })

      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links/character/#{dummy_uuid}"
        )

      assert conn.status == 404
    end

    test "create_link successfully creates note-note link", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      other_note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "note",
          "entity_id" => other_note.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["note_id"] == note.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == other_note.id
    end

    test "list_links includes note-note links", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      other_note = note_fixture(scope, %{game_id: game.id})

      # Create a note-note link first
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "note",
        "entity_id" => other_note.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["note_id"] == note.id
      assert response["data"]["note_name"] == note.name
      assert [note_response] = response["data"]["links"]["notes"]
      assert note_response["id"] == other_note.id
      assert note_response["name"] == other_note.name
    end

    test "delete_link successfully removes note-note link", %{
      conn: conn,
      game: game,
      note: note,
      scope: scope
    } do
      other_note = note_fixture(scope, %{game_id: game.id})

      # Create a note-note link first
      post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
        "entity_type" => "note",
        "entity_id" => other_note.id
      })

      # Delete the link
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/notes/#{note.id}/links/note/#{other_note.id}"
        )

      assert response(conn, 204)

      # Verify link is removed
      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links")
      response = json_response(conn, 200)
      assert response["data"]["links"]["notes"] == []
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/notes/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game.id}/notes/invalid", note: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/api/games/#{game.id}/notes/#{non_existent_id}", note: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/notes/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end

    test "create_link returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/invalid/links", %{
          "entity_type" => "character",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "create_link returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{non_existent_id}/links", %{
          "entity_type" => "character",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for invalid note id format", %{conn: conn, game: game} do
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/notes/invalid/links/character/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for non-existent note", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/notes/#{non_existent_id}/links/character/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end
  end

  defp create_note(%{scope: scope, game: game}) do
    note = note_fixture(scope, %{game_id: game.id})

    %{note: note}
  end
end
