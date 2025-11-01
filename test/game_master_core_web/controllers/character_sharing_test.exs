defmodule GameMasterCoreWeb.CharacterSharingTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup do
    setup_test_game_and_users()
  end

  # ============================================================================
  # Share Entity Authorization Tests
  # ============================================================================

  describe "POST /share authorization - who can share" do
    setup %{game: game, member_1: owner} do
      # Create a private character owned by member_1
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character to Share",
        class: "Wizard",
        level: 10
      })

      %{character: character}
    end

    test "creator can share their entity with another user", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_3: target_user,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: target_user.id,
        permission: "editor"
      })

      assert_success_response(conn, 200)
    end

    test "admin can share any entity", %{
      conn: conn,
      game: game,
      admin: admin,
      member_3: target_user,
      character: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: target_user.id,
        permission: "editor"
      })

      assert_success_response(conn, 200)
    end

    test "game master can share any entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_3: target_user,
      character: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: target_user.id,
        permission: "editor"
      })

      assert_success_response(conn, 200)
    end

    test "non-owner member cannot share entity", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      member_3: target_user,
      character: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: target_user.id,
        permission: "editor"
      })

      # Non-owner member cannot see private entity (filtered from query), gets 404
      assert_not_found_response(conn)
    end

    test "non-member cannot share entity", %{
      conn: conn,
      game: game,
      non_member: non_member,
      member_3: target_user,
      character: character
    } do
      conn = authenticate_api_user(conn, non_member)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: target_user.id,
        permission: "editor"
      })

      # Non-member has no access to game at all
      assert_not_found_response(conn)
    end
  end

  # ============================================================================
  # Share Permission Levels Tests
  # ============================================================================

  describe "share permission types" do
    setup %{game: game, member_1: owner} do
      # Create a private character owned by member_1
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character with Permissions",
        class: "Rogue",
        level: 8
      })

      %{character: character}
    end

    test "sharing with 'editor' permission grants full access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with editor permission
      share_entity_with_user(:character, character, owner, shared_user, game, "editor")

      # Verify shared user can view
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id

      # Verify shared user can update
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Updated by Editor"}
      })
      assert_success_response(conn, 200)

      # Verify shared user can delete
      new_char = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "To Delete",
        class: "Fighter",
        level: 1
      })
      share_entity_with_user(:character, new_char, owner, shared_user, game, "editor")

      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = delete(conn, entity_path(:character, game.id, new_char.id))
      assert conn.status in [200, 204]
    end

    test "sharing with 'viewer' permission grants view-only access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with viewer permission
      share_entity_with_user(:character, character, owner, shared_user, game, "viewer")

      # Verify shared user can view
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["id"] == character.id

      # Verify shared user cannot update
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Attempted Update"}
      })
      assert_unauthorized_response(conn, 403)

      # Verify shared user cannot delete
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = delete(conn, entity_path(:character, game.id, character.id))
      assert_unauthorized_response(conn, 403)
    end

    test "sharing with 'blocked' permission denies all access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with blocked permission
      share_entity_with_user(:character, character, owner, shared_user, game, "blocked")

      # Verify shared user cannot view
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)

      # Verify shared user cannot update
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Attempted Update"}
      })
      assert_not_found_response(conn)

      # Verify shared user cannot delete
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = delete(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "blocked permission overrides viewable visibility", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user
    } do
      # Create viewable entity
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "viewable",
        name: "Viewable But Blocked",
        class: "Cleric",
        level: 5
      })

      # Share with blocked permission
      share_entity_with_user(:character, character, owner, shared_user, game, "blocked")

      # Verify shared user cannot access despite viewable visibility
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "blocked permission overrides editable visibility", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user
    } do
      # Create editable entity
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "editable",
        name: "Editable But Blocked",
        class: "Paladin",
        level: 7
      })

      # Share with blocked permission
      share_entity_with_user(:character, character, owner, shared_user, game, "blocked")

      # Verify shared user cannot access despite editable visibility
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end
  end
end
