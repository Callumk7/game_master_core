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

  # ============================================================================
  # Share Updates (Upsert Behavior) Tests
  # ============================================================================

  describe "share updates" do
    setup %{game: game, member_1: owner} do
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character for Update Tests",
        class: "Barbarian",
        level: 6
      })

      %{character: character}
    end

    test "re-sharing with different permission updates existing share", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with viewer permission
      share_entity_with_user(:character, character, owner, shared_user, game, "viewer")

      # Verify: can view, cannot edit
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)

      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Should Fail"}
      })
      assert_unauthorized_response(conn, 403)

      # Re-share with editor permission
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: shared_user.id,
        permission: "editor"
      })
      assert_success_response(conn, 200)

      # Verify: can now edit
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Now Can Edit"}
      })
      assert_success_response(conn, 200)
    end

    test "changing from editor to viewer removes edit access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with editor permission
      share_entity_with_user(:character, character, owner, shared_user, game, "editor")

      # Verify: can edit
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Editor Update"}
      })
      assert_success_response(conn, 200)

      # Re-share with viewer permission
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: shared_user.id,
        permission: "viewer"
      })
      assert_success_response(conn, 200)

      # Verify: can view but not edit
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)

      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Should Fail"}
      })
      assert_unauthorized_response(conn, 403)
    end

    test "changing from viewer to blocked removes all access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with viewer permission
      share_entity_with_user(:character, character, owner, shared_user, game, "viewer")

      # Verify: can view
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)

      # Re-share with blocked permission
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = post(conn, share_path(:character, game.id, character.id), %{
        user_id: shared_user.id,
        permission: "blocked"
      })
      assert_success_response(conn, 200)

      # Verify: cannot access
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end
  end

  # ============================================================================
  # Unshare Entity Tests
  # ============================================================================

  describe "DELETE /share authorization" do
    setup %{game: game, member_1: owner, member_2: shared_user} do
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character to Unshare",
        class: "Monk",
        level: 12
      })

      # Share with member_2
      share_entity_with_user(:character, character, owner, shared_user, game, "editor")

      %{character: character}
    end

    test "creator can unshare their entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Verify share exists (shared_user can access)
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)

      # Owner unshares
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, share_path(:character, game.id, character.id, shared_user.id))
      assert conn.status in [200, 204]

      # Verify shared_user loses access
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "admin can unshare any entity", %{
      conn: conn,
      game: game,
      admin: admin,
      member_2: shared_user,
      character: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, share_path(:character, game.id, character.id, shared_user.id))
      assert conn.status in [200, 204]

      # Verify shared_user loses access
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "game master can unshare any entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_2: shared_user,
      character: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, share_path(:character, game.id, character.id, shared_user.id))
      assert conn.status in [200, 204]

      # Verify shared_user loses access
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "non-owner member cannot unshare entity", %{
      conn: conn,
      game: game,
      member_3: non_owner,
      member_2: shared_user,
      character: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = delete(conn, share_path(:character, game.id, character.id, shared_user.id))

      # Non-owner cannot access private entity
      assert_not_found_response(conn)
    end

    test "unsharing non-existent share returns not found", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_3: user_without_share,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, share_path(:character, game.id, character.id, user_without_share.id))

      assert_not_found_response(conn)
    end

    test "after unshare, user reverts to visibility-based access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user
    } do
      # Create viewable entity
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "viewable",
        name: "Viewable with Share",
        class: "Druid",
        level: 9
      })

      # Share with editor permission
      share_entity_with_user(:character, character, owner, shared_user, game, "editor")

      # Verify: can edit
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Editor Update"}
      })
      assert_success_response(conn, 200)

      # Unshare
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = delete(conn, share_path(:character, game.id, character.id, shared_user.id))
      assert conn.status in [200, 204]

      # Verify: can view but not edit (reverts to viewable behavior)
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)

      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Should Fail"}
      })
      assert_unauthorized_response(conn, 403)
    end
  end

  # ============================================================================
  # List Shares Tests
  # ============================================================================

  describe "GET /shares authorization" do
    setup %{game: game, member_1: owner, member_2: user2, member_3: user3} do
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character with Multiple Shares",
        class: "Sorcerer",
        level: 14
      })

      # Share with multiple users
      share_entity_with_user(:character, character, owner, user2, game, "editor")
      share_entity_with_user(:character, character, owner, user3, game, "viewer")

      %{character: character}
    end

    test "creator can list shares on their entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "admin can list shares on any entity", %{
      conn: conn,
      game: game,
      admin: admin,
      character: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "game master can list shares on any entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      character: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "member with editor share can list shares", %{
      conn: conn,
      game: game,
      member_2: editor_user,
      character: character
    } do
      conn = authenticate_api_user(conn, editor_user)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "member with viewer share can list shares", %{
      conn: conn,
      game: game,
      member_3: viewer_user,
      character: character
    } do
      conn = authenticate_api_user(conn, viewer_user)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert length(response["data"]) == 2
    end

    test "member without access cannot list shares", %{
      conn: conn,
      game: game,
      member_1: owner
    } do
      # Create private entity, no share for member without access
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "No Share Access",
        class: "Ranger",
        level: 3
      })

      # Use a new user (not member_2 or member_3 who have shares on other entity)
      new_member = GameMasterCore.AccountsFixtures.user_fixture(%{
        email: "noshare@test.com",
        username: "noshare"
      })
      add_game_member(game, new_member, "member")

      conn = authenticate_api_user(conn, new_member)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      # Member cannot access entity, so cannot list shares
      assert_not_found_response(conn)
    end

    test "listed shares include user details and permission type", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: user2,
      member_3: user3,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = get(conn, shares_list_path(:character, game.id, character.id))

      assert_success_response(conn, 200)
      response = json_response(conn, 200)

      shares = response["data"]
      assert length(shares) == 2

      # Check that shares include expected fields
      share_1 = Enum.find(shares, fn s -> s["user"]["id"] == user2.id end)
      assert share_1["permission"] == "editor"
      assert share_1["user"]["username"] == "member2"

      share_2 = Enum.find(shares, fn s -> s["user"]["id"] == user3.id end)
      assert share_2["permission"] == "viewer"
      assert share_2["user"]["username"] == "member3"
    end
  end

  # ============================================================================
  # Update Visibility Tests
  # ============================================================================

  describe "PUT /visibility authorization" do
    setup %{game: game, member_1: owner} do
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "private",
        name: "Character for Visibility Tests",
        class: "Warlock",
        level: 11
      })

      %{character: character}
    end

    test "creator can update visibility of their entity", %{
      conn: conn,
      game: game,
      member_1: owner,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "viewable"
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["visibility"] == "viewable"
    end

    test "admin can update visibility of any entity", %{
      conn: conn,
      game: game,
      admin: admin,
      character: character
    } do
      conn = authenticate_api_user(conn, admin)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "editable"
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["visibility"] == "editable"
    end

    test "game master can update visibility of any entity", %{
      conn: conn,
      game: game,
      game_master: gm,
      character: character
    } do
      conn = authenticate_api_user(conn, gm)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "viewable"
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["visibility"] == "viewable"
    end

    test "non-owner member cannot update visibility", %{
      conn: conn,
      game: game,
      member_2: non_owner,
      character: character
    } do
      conn = authenticate_api_user(conn, non_owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "viewable"
      })

      # Non-owner cannot access private entity
      assert_not_found_response(conn)
    end

    test "invalid visibility value returns bad request", %{
      conn: conn,
      game: game,
      member_1: owner,
      character: character
    } do
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "invalid"
      })

      assert_bad_request_response(conn)
    end

    test "changing from private to viewable grants view access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: other_member,
      character: character
    } do
      # Verify member_2 cannot view private entity
      conn = authenticate_api_user(conn, other_member)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)

      # Change to viewable
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "viewable"
      })
      assert_success_response(conn, 200)

      # Verify member_2 can now view
      conn = build_conn()
      conn = authenticate_api_user(conn, other_member)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_success_response(conn, 200)
    end

    test "changing from editable to private removes access", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: other_member
    } do
      # Create editable entity
      character = create_entity_for_user(:character, owner, game, %{
        visibility: "editable",
        name: "Editable to Private",
        class: "Bard",
        level: 7
      })

      # Verify member_2 can edit
      conn = authenticate_api_user(conn, other_member)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Member Edit"}
      })
      assert_success_response(conn, 200)

      # Change to private
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "private"
      })
      assert_success_response(conn, 200)

      # Verify member_2 cannot access
      conn = build_conn()
      conn = authenticate_api_user(conn, other_member)
      conn = get(conn, entity_path(:character, game.id, character.id))
      assert_not_found_response(conn)
    end

    test "visibility change does not affect explicit shares", %{
      conn: conn,
      game: game,
      member_1: owner,
      member_2: shared_user,
      character: character
    } do
      # Share with editor permission
      share_entity_with_user(:character, character, owner, shared_user, game, "editor")

      # Verify shared_user can edit
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Editor Update"}
      })
      assert_success_response(conn, 200)

      # Change visibility to viewable
      conn = build_conn()
      conn = authenticate_api_user(conn, owner)
      conn = put(conn, visibility_path(:character, game.id, character.id), %{
        visibility: "viewable"
      })
      assert_success_response(conn, 200)

      # Verify shared_user still has editor access (share takes precedence)
      conn = build_conn()
      conn = authenticate_api_user(conn, shared_user)
      conn = put(conn, entity_path(:character, game.id, character.id), %{
        character: %{name: "Still Editor"}
      })
      assert_success_response(conn, 200)
    end
  end
end
