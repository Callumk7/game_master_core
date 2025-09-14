defmodule GameMasterCoreWeb.QuestControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.QuestsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  alias GameMasterCore.Quests.Quest

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
    test "lists all quests", %{conn: conn, scope: _scope, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/quests")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to quests for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/quests")
      end
    end
  end

  describe "create quest" do
    test "renders quest when data is valid", %{conn: conn, scope: _scope, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/quests", quest: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies quest creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/quests", quest: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, scope: _scope, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/quests", quest: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update quest" do
    setup [:create_quest]

    test "renders quest when data is valid", %{
      conn: conn,
      quest: %Quest{id: id} = _quest,
      scope: _scope,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/quests/#{id}", quest: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      quest: quest,
      scope: _scope,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}", quest: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete quest" do
    setup [:create_quest]

    test "deletes chosen quest", %{conn: conn, quest: quest, scope: _scope, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/quests/#{quest}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/quests/#{quest}")
      end
    end

    test "denies deletion for quests in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_game_scope = GameMasterCore.Accounts.Scope.put_game(other_user_scope, other_game)
      other_quest = quest_fixture(other_game_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}")
      end
    end
  end

  describe "quest links" do
    setup [:create_quest]

    test "list_links returns quest links", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Create a link first
      post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      conn = get(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["quest_id"] == quest.id
      assert response["data"]["quest_name"] == quest.name

      assert [character_response] = response["data"]["links"]["characters"]
      assert character_response["id"] == character.id
      assert character_response["name"] == character.name
      assert character_response["class"] == character.class
      assert character_response["level"] == character.level
      assert character_response["description"] == character.description
      assert character_response["image_url"] == character.image_url
      assert character_response["created_at"]
      assert character_response["updated_at"]
    end

    test "list_links returns empty links for quest with no links", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      conn = get(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links")
      response = json_response(conn, 200)

      assert response["data"]["quest_id"] == quest.id
      assert response["data"]["links"]["characters"] == []
      assert response["data"]["links"]["notes"] == []
      assert response["data"]["links"]["factions"] == []
      assert response["data"]["links"]["locations"] == []
    end

    test "create_link successfully creates quest-character link", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => character.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["quest_id"] == quest.id
      assert response["entity_type"] == "character"
      assert response["entity_id"] == character.id
    end

    test "create_link successfully creates quest-note link", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      note = note_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "note",
          "entity_id" => note.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["quest_id"] == quest.id
      assert response["entity_type"] == "note"
      assert response["entity_id"] == note.id
    end

    test "create_link successfully creates quest-faction link", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      faction = faction_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "faction",
          "entity_id" => faction.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["quest_id"] == quest.id
      assert response["entity_type"] == "faction"
      assert response["entity_id"] == faction.id
    end

    test "create_link successfully creates quest-location link", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      location = location_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "location",
          "entity_id" => location.id
        })

      response = json_response(conn, 201)
      assert response["message"] == "Link created successfully"
      assert response["quest_id"] == quest.id
      assert response["entity_type"] == "location"
      assert response["entity_id"] == location.id
    end

    test "create_link with missing entity_type returns error", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_id" => character.id
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity type is required"
    end

    test "create_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "invalid",
          "entity_id" => character.id
        })

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "create_link with missing entity_id returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Entity ID is required"
    end

    test "create_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "create_link with non-existent character returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      non_existent_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => non_existent_uuid
        })

      response = json_response(conn, 404)
      assert response["error"] == "Character not found"
    end

    test "create_link with cross-scope character returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_character = character_fixture(other_scope, %{game_id: other_game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => other_character.id
        })

      response = json_response(conn, 404)
      assert response["error"] == "Character not found"
    end

    test "create_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "item",
          "entity_id" => dummy_uuid
        })

      response = json_response(conn, 422)
      assert response["error"] == "Linking quests to item is not yet supported"
    end

    test "create_link prevents duplicate links", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Create first link
      post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      # Try to create duplicate link
      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => character.id
        })

      assert json_response(conn, 422)["errors"]
    end

    test "delete_link successfully removes quest-character link", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      # Create link first
      post(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links", %{
        "entity_type" => "character",
        "entity_id" => character.id
      })

      # Delete the link
      conn =
        delete(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links/character/#{character.id}")

      assert response(conn, 204)
    end

    test "delete_link with non-existent link returns error", %{
      conn: conn,
      game: game,
      quest: quest,
      scope: scope
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        delete(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links/character/#{character.id}")

      assert json_response(conn, 404)
    end

    test "delete_link with invalid entity_type returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links/invalid/#{dummy_uuid}")

      response = json_response(conn, 400)

      assert response["error"] ==
               "Invalid entity type. Supported types: note, character, faction, location, quest"
    end

    test "delete_link with invalid entity_id returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      conn = delete(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links/character/invalid")
      response = json_response(conn, 400)
      assert response["error"] == "Invalid entity ID format"
    end

    test "delete_link with unsupported entity type returns error", %{
      conn: conn,
      game: game,
      quest: quest
    } do
      dummy_uuid = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/quests/#{quest.id}/links/item/#{dummy_uuid}")
      response = json_response(conn, 422)
      assert response["error"] == "Linking quests to item is not yet supported"
    end

    test "denies access to links for quests in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_game_scope = GameMasterCore.Accounts.Scope.put_game(other_user_scope, other_game)
      other_quest = quest_fixture(other_game_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links")
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        post(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => dummy_uuid
        })
      end

      assert_error_sent 404, fn ->
        dummy_uuid = Ecto.UUID.generate()

        delete(
          conn,
          ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links/character/#{dummy_uuid}"
        )
      end
    end
  end

  defp create_quest(%{scope: scope, game: game}) do
    # Use the game scope for quest creation since quests require game context
    game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
    quest = quest_fixture(game_scope, %{game_id: game.id})

    %{quest: quest}
  end
end
