defmodule GameMasterCoreWeb.CharacterControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.CharactersFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  alias GameMasterCore.Characters.Character

  @create_attrs %{
    name: "some name",
    level: 42,
    content: "some content",
    class: "some class"
  }
  @update_attrs %{
    name: "some updated name",
    level: 43,
    content: "some updated content",
    class: "some updated class"
  }
  @invalid_attrs %{name: nil, level: nil, content: nil, class: nil}

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

      conn = get(conn, ~p"/api/games/#{other_game.id}/characters")
      assert conn.status == 404
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
               "level" => 42,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies character creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = post(conn, ~p"/api/games/#{other_game.id}/characters", character: @create_attrs)
      assert conn.status == 404
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "creates character successfully", %{conn: conn, game: game, scope: _scope} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/characters/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]

      # Verify the response no longer includes the old fields
      character_data = json_response(conn, 200)["data"]
      refute Map.has_key?(character_data, "member_of_faction_id")
      refute Map.has_key?(character_data, "faction_role")
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
               "level" => 43,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, character: character, game: game} do
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character}", character: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "updates character successfully", %{
      conn: conn,
      character: character,
      game: game,
      scope: _scope
    } do
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character}", character: @update_attrs)

      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{id}")

      character_data = json_response(conn, 200)["data"]

      assert %{
               "id" => ^id,
               "name" => "some updated name"
             } = character_data

      # Verify the response no longer includes the old fields
      refute Map.has_key?(character_data, "member_of_faction_id")
      refute Map.has_key?(character_data, "faction_role")
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/characters/#{character}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game}/characters/#{character}")
      assert json_response(conn, 404)
    end

    test "denies deletion for characters in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      conn = delete(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}")
      assert conn.status == 404
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/characters/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent character", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game.id}/characters/invalid", character: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game.id}/characters/invalid")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/characters/invalid/links")
      assert json_response(conn, 404)
    end

    test "create_link returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/invalid/links", %{
          "entity_type" => "note",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for invalid character id format", %{conn: conn, game: game} do
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/characters/invalid/links/note/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
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

      conn = get(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links")
      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links", %{
          "entity_type" => "note",
          "entity_id" => dummy_uuid
        })

      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links/note/#{dummy_uuid}"
        )

      assert conn.status == 404
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

  defp create_character(%{scope: scope, game: game}) do
    character = character_fixture(scope, %{game_id: game.id})

    %{character: character}
  end

  describe "pin character" do
    setup [:create_character]

    test "pins character successfully", %{conn: conn, game: game, character: character} do
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/pin")
      response = json_response(conn, 200)

      assert response["data"]["pinned"] == true
      assert response["data"]["id"] == character.id
    end

    test "returns 404 for non-existent character", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{non_existent_id}/pin")
      assert response(conn, 404)
    end

    test "denies pinning character for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      conn = put(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/pin")
      assert response(conn, 404)
    end
  end

  describe "unpin character" do
    setup [:create_character]

    test "unpins character successfully", %{conn: conn, game: game, character: character} do
      # First pin the character
      put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/pin")

      # Then unpin it
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/unpin")
      response = json_response(conn, 200)

      assert response["data"]["pinned"] == false
      assert response["data"]["id"] == character.id
    end

    test "returns 404 for non-existent character", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{non_existent_id}/unpin")
      assert response(conn, 404)
    end

    test "denies unpinning character for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      conn = put(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/unpin")
      assert response(conn, 404)
    end
  end

  describe "update_link" do
    setup [:create_character]

    test "update_link successfully updates character-note link metadata", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # First create a link
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "note",
        "entity_id" => note.id,
        "relationship_type" => "ally",
        "description" => "Initial relationship",
        "strength" => 5
      })

      # Then update the link
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/#{note.id}", %{
          "relationship_type" => "enemy",
          "description" => "Updated to enemy",
          "strength" => 8
        })

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
      assert response["updated_at"]
    end

    test "update_link successfully updates character-faction link metadata", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      faction = faction_fixture(scope, %{game_id: game.id})

      # First create a link
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "faction",
        "entity_id" => faction.id,
        "relationship_type" => "member",
        "strength" => 7
      })

      # Then update the link
      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/faction/#{faction.id}",
          %{
            "relationship_type" => "leader",
            "description" => "Promoted to leader",
            "strength" => 10
          }
        )

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "faction"
      assert response["entity_id"] == faction.id
    end

    test "update_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      # Try to update a link that doesn't exist
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/#{note.id}", %{
          "relationship_type" => "enemy",
          "description" => "Should fail",
          "strength" => 8
        })

      assert json_response(conn, 404)
    end

    test "update_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      character: character
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/invalid_type/#{dummy_uuid}",
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
      character: character
    } do
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links/note/invalid_id", %{
          "relationship_type" => "ally"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "update_link with non-existent character returns 404", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})
      non_existent_id = Ecto.UUID.generate()

      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/characters/#{non_existent_id}/links/note/#{note.id}",
          %{
            "relationship_type" => "ally"
          }
        )

      assert response(conn, 404)
    end

    test "denies access to update_link for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      conn =
        put(
          conn,
          ~p"/api/games/#{other_game.id}/characters/#{other_character.id}/links/note/#{other_note.id}",
          %{
            "relationship_type" => "ally"
          }
        )

      assert response(conn, 404)
    end

    test "create_link successfully creates character-location link with is_current_location metadata",
         %{
           conn: conn,
           game: game,
           character: character,
           scope: scope
         } do
      location = location_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "location",
          "entity_id" => location.id,
          "is_current_location" => true,
          "description" => "Current residence",
          "strength" => 8
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "create_link successfully creates character-location link with is_current_location false",
         %{
           conn: conn,
           game: game,
           character: character,
           scope: scope
         } do
      location = location_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
          "entity_type" => "location",
          "entity_id" => location.id,
          "is_current_location" => false,
          "description" => "Former residence"
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "update_link successfully updates character-location link with is_current_location metadata",
         %{
           conn: conn,
           game: game,
           character: character,
           scope: scope
         } do
      location = location_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location.id,
        "is_current_location" => false
      })

      # Update the link with new metadata
      conn =
        put(
          conn,
          ~p"/api/games/#{game.id}/characters/#{character.id}/links/location/#{location.id}",
          %{
            "is_current_location" => true,
            "description" => "Now current residence",
            "strength" => 10
          }
        )

      response = json_response(conn, 200)
      assert response["message"] == "Link updated successfully"
      assert response["character_id"] == character.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "list_links returns character links with is_current_location metadata", %{
      conn: conn,
      game: game,
      character: character,
      scope: scope
    } do
      location1 = location_fixture(scope, %{game_id: game.id, name: "Current Home"})
      location2 = location_fixture(scope, %{game_id: game.id, name: "Former Home"})

      # Create links with different is_current_location values
      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location1.id,
        "is_current_location" => true,
        "description" => "Current residence"
      })

      post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links", %{
        "entity_type" => "location",
        "entity_id" => location2.id,
        "is_current_location" => false,
        "description" => "Former residence"
      })

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["character_id"] == character.id
      assert length(response["data"]["links"]["locations"]) == 2

      locations = response["data"]["links"]["locations"]
      current_location = Enum.find(locations, fn loc -> loc["name"] == "Current Home" end)
      former_location = Enum.find(locations, fn loc -> loc["name"] == "Former Home" end)

      assert current_location["is_current_location"] == true
      assert current_location["description_meta"] == "Current residence"

      assert former_location["is_current_location"] == false
      assert former_location["description_meta"] == "Former residence"
    end
  end
end
