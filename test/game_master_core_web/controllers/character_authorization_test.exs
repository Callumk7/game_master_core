defmodule GameMasterCoreWeb.CharacterAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

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

  # ============================================================================
  # Game Master Role Permission Tests
  # ============================================================================

  describe "game master role permissions - view" do
    test "game master can view private entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      private_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Private Character"
    end

    test "game master can view viewable entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Viewable Character"
    end

    test "game master can view editable entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Editable Character"
    end
  end

  describe "game master role permissions - update" do
    test "game master can update private entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      private_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "GM Updated Private"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "GM Updated Private"
    end

    test "game master can update viewable entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "GM Updated Viewable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "GM Updated Viewable"
    end

    test "game master can update editable entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "GM Updated Editable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "GM Updated Editable"
    end
  end

  describe "game master role permissions - delete" do
    test "game master can delete private entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "private",
        name: "GM To Delete",
        class: "Ranger",
        level: 4
      })

      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "game master can delete viewable entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "viewable",
        name: "GM To Delete Viewable",
        class: "Bard",
        level: 6
      })

      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "game master can delete editable entity they don't own", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_1: member
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, member, game, %{
        visibility: "editable",
        name: "GM To Delete Editable",
        class: "Druid",
        level: 8
      })

      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end
  end

  # ============================================================================
  # Entity Owner Permission Tests
  # ============================================================================

  describe "entity owner permissions - view" do
    test "owner can view own private entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      private_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Private Character"
    end

    test "owner can view own viewable entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Viewable Character"
    end

    test "owner can view own editable entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Editable Character"
    end
  end

  describe "entity owner permissions - update" do
    test "owner can update own private entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      private_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Owner Updated Private"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Owner Updated Private"
    end

    test "owner can update own viewable entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Owner Updated Viewable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Owner Updated Viewable"
    end

    test "owner can update own editable entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Owner Updated Editable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Owner Updated Editable"
    end
  end

  describe "entity owner permissions - delete" do
    test "owner can delete own private entity", %{
      conn: conn,
      game: game,
      member_1: owner
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Owner To Delete Private",
        class: "Monk",
        level: 9
      })

      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "owner can delete own viewable entity", %{
      conn: conn,
      game: game,
      member_1: owner
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, owner, game, %{
        visibility: "viewable",
        name: "Owner To Delete Viewable",
        class: "Barbarian",
        level: 11
      })

      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end

    test "owner can delete own editable entity", %{
      conn: conn,
      game: game,
      member_1: owner
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, owner, game, %{
        visibility: "editable",
        name: "Owner To Delete Editable",
        class: "Sorcerer",
        level: 13
      })

      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end
  end

  # ============================================================================
  # Member (Non-Owner) Access Tests - Private Visibility
  # ============================================================================

  describe "member access to private entities" do
    test "member cannot view another member's private entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      private_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      # Entity is filtered from query results, returns 404
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      private_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Attempted Update"}
      })

      # Entity is filtered from query results, returns 404
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      private_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = delete(conn, entity_path(:character, game.id, character.id))

      # Entity is filtered from query results, returns 404
      assert_not_found_response(conn)
    end
  end

  # ============================================================================
  # Member (Non-Owner) Access Tests - Viewable Visibility
  # ============================================================================

  describe "member access to viewable entities" do
    test "member can view another member's viewable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Viewable Character"
    end

    test "member cannot update another member's viewable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Attempted Update"}
      })

      # Member can view but not edit viewable entities
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = delete(conn, entity_path(:character, game.id, character.id))

      # Member can view but not delete viewable entities
      assert_unauthorized_response(conn, 403)
    end
  end

  # ============================================================================
  # Member (Non-Owner) Access Tests - Editable Visibility
  # ============================================================================

  describe "member access to editable entities" do
    test "member can view another member's editable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = get(conn, entity_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id
      assert response["data"]["name"] == "Editable Character"
    end

    test "member can update another member's editable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Member Updated Editable"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Member Updated Editable"
    end

    test "member can delete another member's editable entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      member_1: owner
    } do
      # Create a character specifically for deletion
      char_to_delete = create_entity_for_user(:character, owner, game, %{
        visibility: "editable",
        name: "Member To Delete Editable",
        class: "Wizard",
        level: 15
      })

      conn = authenticate_api_user(conn, non_owner)
      conn = delete(conn, entity_path(:character, game.id, char_to_delete.id))

      assert conn.status in [200, 204]
    end
  end

  # ============================================================================
  # Non-Member Access Tests
  # ============================================================================

  describe "non-member access" do
    test "non-member cannot view private entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      private_char: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = get(conn, entity_path(:character, game.id, character.id))

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = get(conn, entity_path(:character, game.id, character.id))

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = get(conn, entity_path(:character, game.id, character.id))

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end

    test "non-member cannot update any entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      viewable_char: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Attempted Update"}
      })

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      editable_char: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = delete(conn, entity_path(:character, game.id, character.id))

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end

    test "non-member cannot list game entities", %{
      conn: conn,
      game: game,
      non_member: non_member
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = get(conn, entity_path(:character, game.id))

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end
  end
end
