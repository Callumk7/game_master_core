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

      conn = get(conn, ~p"/api/games/#{other_game.id}/quests")
      assert conn.status == 404
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
               "name" => "some name",
               "parent_id" => nil
             } = json_response(conn, 200)["data"]
    end

    test "renders quest with parent_id when data is valid", %{
      conn: conn,
      scope: scope,
      game: game
    } do
      # Create parent quest first
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
      parent_quest = quest_fixture(game_scope, %{game_id: game.id})

      attrs_with_parent = Map.put(@create_attrs, :parent_id, parent_quest.id)
      conn = post(conn, ~p"/api/games/#{game}/quests", quest: attrs_with_parent)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name",
               "parent_id" => parent_id
             } = json_response(conn, 200)["data"]

      assert parent_id == parent_quest.id
    end

    test "denies quest creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = post(conn, ~p"/api/games/#{other_game.id}/quests", quest: @create_attrs)
      assert conn.status == 404
    end

    test "renders errors when data is invalid", %{conn: conn, scope: _scope, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/quests", quest: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders error when parent quest does not exist", %{
      conn: conn,
      scope: _scope,
      game: game
    } do
      invalid_parent_id = Ecto.UUID.generate()
      attrs_with_invalid_parent = Map.put(@create_attrs, :parent_id, invalid_parent_id)

      conn = post(conn, ~p"/api/games/#{game}/quests", quest: attrs_with_invalid_parent)
      response = json_response(conn, 422)

      assert response["errors"]["parent_id"] == [
               "parent quest does not exist or does not belong to the same game"
             ]
    end

    test "renders error when parent quest belongs to different game", %{
      conn: conn,
      scope: _scope,
      game: game
    } do
      # Create a quest in a different game
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_game_scope = GameMasterCore.Accounts.Scope.put_game(other_user_scope, other_game)
      other_quest = quest_fixture(other_game_scope, %{game_id: other_game.id})

      attrs_with_cross_game_parent = Map.put(@create_attrs, :parent_id, other_quest.id)

      conn = post(conn, ~p"/api/games/#{game}/quests", quest: attrs_with_cross_game_parent)
      response = json_response(conn, 422)

      assert response["errors"]["parent_id"] == [
               "parent quest does not exist or does not belong to the same game"
             ]
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
               "name" => "some updated name",
               "parent_id" => nil
             } = json_response(conn, 200)["data"]
    end

    test "renders quest when updating parent_id", %{
      conn: conn,
      quest: %Quest{id: id} = _quest,
      scope: scope,
      game: game
    } do
      # Create parent quest
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
      parent_quest = quest_fixture(game_scope, %{game_id: game.id})

      update_attrs_with_parent = Map.put(@update_attrs, :parent_id, parent_quest.id)
      conn = put(conn, ~p"/api/games/#{game}/quests/#{id}", quest: update_attrs_with_parent)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name",
               "parent_id" => parent_id
             } = json_response(conn, 200)["data"]

      assert parent_id == parent_quest.id
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

    test "renders error when trying to set quest as its own parent", %{
      conn: conn,
      quest: quest,
      scope: _scope,
      game: game
    } do
      update_attrs_self_parent = Map.put(@update_attrs, :parent_id, quest.id)
      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}", quest: update_attrs_self_parent)
      response = json_response(conn, 422)

      assert response["errors"]["parent_id"] == ["quest cannot be its own parent"]
    end

    test "renders error when trying to create circular reference", %{
      conn: conn,
      quest: quest,
      scope: scope,
      game: game
    } do
      # Create child quest with quest as parent
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
      child_quest = quest_fixture(game_scope, %{game_id: game.id, parent_id: quest.id})

      # Try to make the original quest a child of its child (circular reference)
      update_attrs_circular = Map.put(@update_attrs, :parent_id, child_quest.id)
      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}", quest: update_attrs_circular)
      response = json_response(conn, 422)

      assert response["errors"]["parent_id"] == ["would create a circular reference"]
    end
  end

  describe "delete quest" do
    setup [:create_quest]

    test "deletes chosen quest", %{conn: conn, quest: quest, scope: _scope, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/quests/#{quest}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}")
      assert json_response(conn, 404)
    end

    test "denies deletion for quests in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_game_scope = GameMasterCore.Accounts.Scope.put_game(other_user_scope, other_game)
      other_quest = quest_fixture(other_game_scope, %{game_id: other_game.id})

      conn = delete(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}")
      assert conn.status == 404
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
      assert character_response["content"] == character.content
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

      conn = get(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links")
      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links", %{
          "entity_type" => "character",
          "entity_id" => dummy_uuid
        })

      assert conn.status == 404

      dummy_uuid = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{other_game.id}/quests/#{other_quest.id}/links/character/#{dummy_uuid}"
        )

      assert conn.status == 404
    end
  end

  describe "quest tree" do
    test "returns empty tree when no quests exist", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      assert response["data"] == []
    end

    test "returns flat tree structure for single level quests", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Create two root quests
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      quest1 =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Ancient Prophecy",
          content: "Discover the ancient prophecy",
          parent_id: nil
        })

      quest2 =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Dragon Hunt",
          content: "Hunt the legendary dragon",
          parent_id: nil
        })

      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 2

      # Should be sorted by name
      [first, second] = response["data"]
      assert first["name"] == "Ancient Prophecy"
      assert first["id"] == quest1.id
      assert first["children"] == []

      assert second["name"] == "Dragon Hunt"
      assert second["id"] == quest2.id
      assert second["children"] == []
    end

    test "returns hierarchical tree structure with parent-child relationships", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      # Create main quest (root)
      main_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "The Great Adventure",
          content: "Embark on the great adventure",
          parent_id: nil
        })

      # Create sub-quest (child of main quest)
      sub_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Find the Key",
          content: "Locate the ancient key",
          parent_id: main_quest.id
        })

      # Create sub-sub-quest (child of sub-quest)
      sub_sub_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Talk to Oracle",
          content: "Speak with the wise oracle",
          parent_id: sub_quest.id
        })

      # Create another sub-quest in the same main quest
      sub_quest2 =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Gather Supplies",
          content: "Collect necessary supplies",
          parent_id: main_quest.id
        })

      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1

      # Check main quest level
      [main_quest_data] = response["data"]
      assert main_quest_data["name"] == "The Great Adventure"
      assert main_quest_data["id"] == main_quest.id
      assert main_quest_data["content"] == "Embark on the great adventure"
      assert main_quest_data["parent_id"] == nil

      # Check sub-quest level (should be sorted by name)
      assert length(main_quest_data["children"]) == 2
      [sub1_data, sub2_data] = main_quest_data["children"]
      assert sub1_data["name"] == "Find the Key"
      assert sub1_data["id"] == sub_quest.id
      assert sub1_data["parent_id"] == main_quest.id

      assert sub2_data["name"] == "Gather Supplies"
      assert sub2_data["id"] == sub_quest2.id
      assert sub2_data["children"] == []

      # Check sub-sub-quest level
      assert length(sub1_data["children"]) == 1
      [sub_sub_data] = sub1_data["children"]
      assert sub_sub_data["name"] == "Talk to Oracle"
      assert sub_sub_data["id"] == sub_sub_quest.id
      assert sub_sub_data["children"] == []
    end

    test "includes all quest fields in tree response", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Test Quest",
          content: "A test quest content",
          content_plain_text: "A test quest content",
          tags: ["test", "example"],
          parent_id: nil
        })

      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      [quest_data] = response["data"]
      assert quest_data["id"] == quest.id
      assert quest_data["name"] == "Test Quest"
      assert quest_data["content"] == "A test quest content"
      assert quest_data["content_plain_text"] == "A test quest content"
      assert quest_data["tags"] == ["test", "example"]
      assert quest_data["parent_id"] == nil
      assert quest_data["children"] == []
    end

    test "handles deep nesting correctly", %{conn: conn, game: game, scope: scope} do
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      # Create a 4-level hierarchy
      main_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Main Quest",
          content: "Main quest",
          parent_id: nil
        })

      sub_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Sub Quest",
          content: "Sub quest",
          parent_id: main_quest.id
        })

      sub_sub_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Sub Sub Quest",
          content: "Sub sub quest",
          parent_id: sub_quest.id
        })

      _final_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Final Quest",
          content: "Final quest",
          parent_id: sub_sub_quest.id
        })

      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      [main_data] = response["data"]
      [sub_data] = main_data["children"]
      [sub_sub_data] = sub_data["children"]
      [final_data] = sub_sub_data["children"]

      assert main_data["name"] == "Main Quest"
      assert sub_data["name"] == "Sub Quest"
      assert sub_sub_data["name"] == "Sub Sub Quest"
      assert final_data["name"] == "Final Quest"
      assert final_data["children"] == []
    end

    test "only returns quests for the specified game", %{conn: conn, game: game, scope: scope} do
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      # Create quest in this game
      _our_quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Our Quest",
          content: "Our quest"
        })

      # Create another game and quest
      other_scope = user_scope_fixture()
      other_game = game_fixture(other_scope)
      other_game_scope = GameMasterCore.Accounts.Scope.put_game(other_scope, other_game)

      _other_quest =
        quest_fixture(other_game_scope, %{
          game_id: other_game.id,
          name: "Other Quest",
          content: "Other quest"
        })

      conn = get(conn, ~p"/api/games/#{game}/quests/tree")
      response = json_response(conn, 200)

      # Should only return our quest
      assert length(response["data"]) == 1
      [quest_data] = response["data"]
      assert quest_data["name"] == "Our Quest"
    end

    test "denies access to tree for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = get(conn, ~p"/api/games/#{other_game.id}/quests/tree")
      assert conn.status == 404
    end

    test "allows game members to access quest tree", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)
      game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)

      # Create a quest
      _quest =
        quest_fixture(game_scope, %{
          game_id: game.id,
          name: "Member Quest",
          content: "Member quest"
        })

      # Login as member
      member_conn = authenticate_api_user(build_conn(), member_scope.user)

      conn = get(member_conn, ~p"/api/games/#{game.id}/quests/tree")
      response = json_response(conn, 200)

      assert length(response["data"]) == 1
      [quest_data] = response["data"]
      assert quest_data["name"] == "Member Quest"
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/quests/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/quests/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game.id}/quests/invalid", quest: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        put(conn, ~p"/api/games/#{game.id}/quests/#{non_existent_id}", quest: %{name: "test"})

      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game.id}/quests/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game.id}/quests/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/quests/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_links returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game.id}/quests/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end

    test "create_link returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/invalid/links", %{
          "entity_type" => "character",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "create_link returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game.id}/quests/#{non_existent_id}/links", %{
          "entity_type" => "character",
          "entity_id" => Ecto.UUID.generate()
        })

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for invalid quest id format", %{conn: conn, game: game} do
      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/quests/invalid/links/character/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end

    test "delete_link returns 404 for non-existent quest", %{conn: conn, game: game} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        delete(
          conn,
          ~p"/api/games/#{game.id}/quests/#{non_existent_id}/links/character/#{Ecto.UUID.generate()}"
        )

      assert json_response(conn, 404)
    end
  end

  defp create_quest(%{scope: scope, game: game}) do
    # Use the game scope for quest creation since quests require game context
    game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
    quest = quest_fixture(game_scope, %{game_id: game.id})

    %{quest: quest}
  end
end
