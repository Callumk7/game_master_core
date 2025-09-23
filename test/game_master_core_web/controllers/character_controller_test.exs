defmodule GameMasterCoreWeb.CharacterControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.CharactersFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures
  alias GameMasterCore.Characters.Character

  @create_attrs %{
    name: "some name",
    level: 42,
    content: "some content",
    class: "some class",
    image_url: "some image_url"
  }
  @update_attrs %{
    name: "some updated name",
    level: 43,
    content: "some updated content",
    class: "some updated class",
    image_url: "some updated image_url"
  }
  @invalid_attrs %{name: nil, level: nil, content: nil, class: nil, image_url: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, game: game}
  end

  describe "index" do
    test "lists all characters", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/characters")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to characters for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/characters")
      end
    end
  end

  describe "create character" do
    test "renders character when data is valid for owned game", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/characters/#{id}")

      assert %{
               "id" => ^id,
               "class" => "some class",
               "content" => "some content",
               "image_url" => "some image_url",
               "level" => 42,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies character creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/characters", character: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update character" do
    setup [:create_character]

    test "renders character when data is valid", %{
      conn: conn,
      character: %Character{id: id} = _character,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{id}", character: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{id}")

      assert %{
               "id" => ^id,
               "class" => "some updated class",
               "content" => "some updated content",
               "image_url" => "some updated image_url",
               "level" => 43,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, character: character, game: game} do
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character}", character: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/characters/#{character}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/characters/#{character}")
      end
    end

    test "denies deletion for characters in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}")
      end
    end
  end

  describe "character links" do
    setup [:create_character]

    test "list_links returns character links", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create a link first
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert response["data"]["character_name"] == character.name

      assert [note_response] = response["data"]["links"]["notes"]
      assert note_response["id"] == note.id
      assert note_response["name"] == note.name
      assert note_response["content"] == note.content
      assert note_response["created_at"]
      assert note_response["updated_at"]
    end

    test "list_links returns empty links for character with no links", %{
      conn: conn,
      game: game,
      character: character
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert response["data"]["links"]["notes"] == []
    end

    test "create_link successfully creates character-note link", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
    end

    test "create_link with missing entity_type returns error", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_id" => note.id
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity type is required"
    end

    test "create_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
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
      character: character
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity ID is required"
    end

    test "create_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with non-existent note returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      non_existent_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => non_existent_uuid
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with cross-scope note returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_note = note_fixture(other_scope, %{game_id: other_game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => other_note.id
        })

      response = json_response(conn, 404)
      assert response["error"] == "Note not found"
    end

    test "create_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "item",
          "entity_id" => dummy_uuid
        })

      response = json_response(conn, 422)
      assert response["error"] == "Linking characters to item is not yet supported"
    end

    test "create_link prevents duplicate links", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create first link
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Try to create duplicate link
      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      assert json_response(conn, 422)["errors"]
    end

    test "delete_link successfully removes character-note link", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id
      })

      # Delete the link
      conn =
        delete(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/#{note.id}")

      assert response(conn, 204)
    end

    test "delete_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        delete(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/#{note.id}")

      assert json_response(conn, 404)
    end

    test "delete_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/invalid/#{dummy_uuid}"
        )

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "delete_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/invalid")
      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "delete_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/item/#{dummy_uuid}"
        )

      response = json_response(conn, 422)
      assert response["error"] == "Linking characters to item is not yet supported"
    end

    test "denies access to links for characters in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links")
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        post(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => dummy_uuid
        })
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        delete(
          conn,
          ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links/note/#{dummy_uuid}"
        )
      end
    end

    test "create_link successfully creates character-character link", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      other_character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "character",
          "entity_id" => other_character.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "character"
      assert response["entity_id"] == other_character.id
    end

    test "list_links includes character-character links", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      other_character = character_fixture(scope, %{game_id: game.id})

      # Create a character-character link first
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "character",
        "entity_id" => other_character.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert response["data"]["character_name"] == character.name
      assert [character_response] = response["data"]["links"]["characters"]
      assert character_response["id"] == other_character.id
      assert character_response["name"] == other_character.name
    end

    test "delete_link successfully removes character-character link", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      other_character = character_fixture(scope, %{game_id: game.id})

      # Create a character-character link first
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "character",
        "entity_id" => other_character.id
      })

      # Delete the link
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/character/#{other_character.id}"
        )

      assert response(conn, 204)

      # Verify link is removed
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links")
      response = json_response(conn, 200)
      assert response["data"]["links"]["characters"] == []
    end
  end

  describe "character notes tree" do
    setup [:create_character]

    test "notes_tree returns empty tree for character with no notes", %{
      conn: conn,
      game: game,
      character: character
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert response["data"]["character_name"] == character.name
      assert response["data"]["notes_tree"] == []
    end

    test "notes_tree returns direct child notes", %{
      conn: conn,
      scope: scope,
      game: game,
      character: character
    } do
      # Create notes attached to character
      _note1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character Note 1",
          content: "Content 1",
          parent_id: character.id,
          parent_type: "character"
        })

      _note2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character Note 2",
          content: "Content 2",
          parent_id: character.id,
          parent_type: "character"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert response["data"]["character_name"] == character.name

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 2

      # Verify note structure (should be sorted alphabetically)
      [first_note, second_note] = notes_tree
      assert first_note["name"] == "Character Note 1"
      assert first_note["content"] == "Content 1"
      assert first_note["parent_id"] == character.id
      assert first_note["parent_type"] == "character"
      assert first_note["children"] == []

      assert second_note["name"] == "Character Note 2"
      assert second_note["content"] == "Content 2"
      assert second_note["children"] == []
    end

    test "notes_tree returns hierarchical structure with note children", %{
      conn: conn,
      scope: scope,
      game: game,
      character: character
    } do
      # Create root note attached to character
      root_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Root Note",
          content: "Root content",
          parent_id: character.id,
          parent_type: "character"
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
      grandchild_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Grandchild Note",
          content: "Grandchild content",
          parent_id: child_note.id
        })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      response = json_response(conn, 200)

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 1

      # Check root note
      root = hd(notes_tree)
      assert root["name"] == "Root Note"
      assert root["id"] == root_note.id
      assert root["parent_id"] == character.id
      assert root["parent_type"] == "character"

      # Check child structure
      children = root["children"]
      assert length(children) == 1
      child = hd(children)
      assert child["name"] == "Child Note"
      assert child["id"] == child_note.id
      assert child["parent_id"] == root_note.id
      assert child["parent_type"] == nil

      # Check grandchild structure
      grandchildren = child["children"]
      assert length(grandchildren) == 1
      grandchild = hd(grandchildren)
      assert grandchild["name"] == "Grandchild Note"
      assert grandchild["id"] == grandchild_note.id
      assert grandchild["children"] == []
    end

    test "notes_tree excludes notes from other characters", %{
      conn: conn,
      scope: scope,
      game: game,
      character: character
    } do
      # Create another character
      other_character = character_fixture(scope, %{game_id: game.id, name: "Other Character"})

      # Note for our character
      _note1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "My Character Note",
          parent_id: character.id,
          parent_type: "character"
        })

      # Note for other character
      _note2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Other Character Note",
          parent_id: other_character.id,
          parent_type: "character"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      response = json_response(conn, 200)

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 1
      assert hd(notes_tree)["name"] == "My Character Note"
    end

    test "notes_tree returns 404 for non-existent character", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game.id}/characters/#{non_existent_id}/notes/tree")
      end
    end

    test "notes_tree requires authentication", %{game: game, character: character} do
      conn = build_conn()
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      assert response(conn, 401)
    end

    test "notes_tree respects game access permissions", %{
      conn: conn,
      character: character
    } do
      # Try to access character from a different game
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/characters/#{character.id}/notes/tree")
      end
    end

    test "notes_tree orders notes alphabetically at each level", %{
      conn: conn,
      scope: scope,
      game: game,
      character: character
    } do
      # Create notes in non-alphabetical order
      _note_z =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Z Note",
          parent_id: character.id,
          parent_type: "character"
        })

      _note_a =
        note_fixture(scope, %{
          game_id: game.id,
          name: "A Note",
          parent_id: character.id,
          parent_type: "character"
        })

      _note_m =
        note_fixture(scope, %{
          game_id: game.id,
          name: "M Note",
          parent_id: character.id,
          parent_type: "character"
        })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/notes/tree")
      response = json_response(conn, 200)

      notes_tree = response["data"]["notes_tree"]
      assert length(notes_tree) == 3

      note_names = Enum.map(notes_tree, & &1["name"])
      assert note_names == ["A Note", "M Note", "Z Note"]
    end
  end

  defp create_character(%{scope: scope, game: game}) do
    character = character_fixture(scope, %{game_id: game.id})

    %{character: character}
  end
end
