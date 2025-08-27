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
    user_token = GameMasterCore.Accounts.create_user_api_token(user)
    game = game_fixture(scope)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user_token}")

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

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/notes")
      end
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

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/notes", note: @create_attrs)
      end
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

      assert_error_sent 404, fn ->
        put(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}", note: @update_attrs)
      end
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

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}")
      end
    end

    test "denies deletion for notes in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}")
      end
    end
  end

  describe "game member access" do
    test "allows game members to access notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_token = GameMasterCore.Accounts.create_user_api_token(member_scope.user)

      member_conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{member_token}")

      conn = get(member_conn, ~p"/api/games/#{game.id}/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "allows game members to create notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_token = GameMasterCore.Accounts.create_user_api_token(member_scope.user)

      member_conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{member_token}")

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

      assert response["data"]["links"]["characters"] == [
               %{
                 "id" => character.id,
                 "name" => character.name,
                 "level" => character.level,
                 "class" => character.class
               }
             ]
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
               "Invalid entity type. Supported types: note, character, faction, item, location, quest"
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
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => 999_999
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
      conn =
        post(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links", %{
          "entity_type" => "item",
          "entity_id" => 1
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
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/invalid/1")
      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, item, location, quest"
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
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}/links/item/1")
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

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links")
      end

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links", %{
          "entity_type" => "character",
          "entity_id" => 1
        })
      end

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}/links/character/1")
      end
    end
  end

  defp create_note(%{scope: scope, game: game}) do
    note = note_fixture(scope, %{game_id: game.id})

    %{note: note}
  end
end
