defmodule GameMasterCoreWeb.CharacterAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  alias GameMasterCore.Accounts.Scope

  setup do
    context = setup_test_game_and_users()

    # Create test characters with different visibility levels owned by member_1
    private_char = create_entity_for_user(:character, context.member_1, context.game, %{
      visibility: "private",
      name: "Private Character",
      class: "Warrior",
      level: 5
    })

    viewable_char = create_entity_for_user(:character, context.member_1, context.game, %{
      visibility: "viewable",
      name: "Viewable Character",
      class: "Mage",
      level: 10
    })

    editable_char = create_entity_for_user(:character, context.member_1, context.game, %{
      visibility: "editable",
      name: "Editable Character",
      class: "Rogue",
      level: 7
    })

    Map.merge(context, %{
      private_char: private_char,
      viewable_char: viewable_char,
      editable_char: editable_char
    })
  end

  # ============================================================================
  # Admin Role Permission Tests
  # ============================================================================

  describe "admin role permissions - view" do
    test "admin can view private entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      private_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Private Character"
    end

    test "admin can view viewable entity", %{
      conn: conn,
      game: game,
      admin: admin,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Viewable Character"
    end

    test "admin can view editable entity", %{
      conn: conn,
      game: game,
      admin: admin,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Editable Character"
    end
  end

  describe "admin role permissions - update" do
    test "admin can update private entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      private_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Admin Updated Private"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Admin Updated Private"
    end

    test "admin can update viewable entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Admin Updated Viewable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Admin Updated Viewable"
    end

    test "admin can update editable entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Admin Updated Editable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Admin Updated Editable"
    end
  end

  describe "admin role permissions - delete" do
    test "admin can delete private entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "private",
        name: "To Delete",
        class: "Fighter",
        level: 1
      })

      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "admin can delete viewable entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "viewable",
        name: "To Delete Viewable",
        class: "Cleric",
        level: 3
      })

      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "admin can delete editable entity they don't own", %{
      conn: conn,
      game: game,
      admin: admin,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "editable",
        name: "To Delete Editable",
        class: "Paladin",
        level: 2
      })

      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end
  end
end
