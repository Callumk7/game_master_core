defmodule GameMasterCoreWeb.CharacterSharingTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "share authorization" do
    setup %{member_1: member_1, member_2: member_2, member_3: member_3, test_game: game} do
      # member_1 creates a private character to share
      character = create_entity_for_user(:character, member_1, game, "private")
      %{character: character}
    end

    test "entity creator can share with editor permission", %{member_1: member_1, member_2: member_2, character: character} do
      conn = authenticated_conn(member_1)

      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)
    end

    test "entity creator can share with viewer permission", %{member_1: member_1, member_2: member_2, character: character} do
      conn = authenticated_conn(member_1)

      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "viewer"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)
    end

    test "entity creator can share with blocked permission", %{member_1: member_1, member_2: member_2, character: character} do
      conn = authenticated_conn(member_1)

      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "blocked"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)
    end

    test "non-creator cannot share entity", %{member_2: member_2, member_3: member_3, character: character} do
      conn = authenticated_conn(member_2)

      share_attrs = %{
        "user_id" => member_3.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "admin can share any entity", %{admin: admin, member_2: member_2, character: character} do
      conn = authenticated_conn(admin)

      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can share any entity", %{game_master: game_master, member_2: member_2, character: character} do
      conn = authenticated_conn(game_master)

      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)
    end
  end

  describe "share permission types" do
    setup %{member_1: member_1, member_2: member_2, member_3: member_3, test_game: game} do
      # member_1 creates and shares character with different permissions
      character = create_entity_for_user(:character, member_1, game, "private")

      # Share with editor permission
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_2, "editor")
      # Share with viewer permission
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_3, "viewer")

      %{character: character}
    end

    test "editor share allows view and edit", %{member_2: member_2, character: character} do
      conn = authenticated_conn(member_2)

      # Can view
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)

      # Can update
      update_attrs = %{"character" => %{"name" => "Updated by Editor"}}
      conn = authenticated_conn(member_2)
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "viewer share allows view but not edit", %{member_3: member_3, character: character} do
      conn = authenticated_conn(member_3)

      # Can view
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)

      # Cannot update
      update_attrs = %{"character" => %{"name" => "Should not update"}}
      conn = authenticated_conn(member_3)
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "blocked share denies access", %{member_1: member_1, member_2: member_2, character: character, test_game: game} do
      # Block member_2
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_2, "blocked")

      conn = authenticated_conn(member_2)

      # Cannot view
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)

      # Cannot update
      update_attrs = %{"character" => %{"name" => "Should not update"}}
      conn = authenticated_conn(member_2)
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_not_found_response(conn)
    end
  end

  describe "share updates" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      character = create_entity_for_user(:character, member_1, game, "private")
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_2, "viewer")
      %{character: character}
    end

    test "can update share permission", %{member_1: member_1, member_2: member_2, character: character} do
      conn = authenticated_conn(member_1)

      # Update from viewer to editor
      share_attrs = %{
        "user_id" => member_2.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_success_response(conn, 200)

      # Verify member_2 can now edit
      conn = authenticated_conn(member_2)
      update_attrs = %{"character" => %{"name" => "Updated by Editor"}}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "non-owner cannot update shares", %{member_2: member_2, member_3: member_3, character: character} do
      conn = authenticated_conn(member_2)

      share_attrs = %{
        "user_id" => member_3.id,
        "permission" => "editor"
      }

      conn = post(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share", share_attrs)
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "unshare tests" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      character = create_entity_for_user(:character, member_1, game, "private")
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_2, "editor")
      %{character: character}
    end

    test "owner can unshare entity", %{member_1: member_1, member_2: member_2, character: character} do
      conn = authenticated_conn(member_1)

      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share/#{member_2.id}")
      assert_success_response(conn, 200)

      # Verify member_2 can no longer access
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "non-owner cannot unshare", %{member_2: member_2, member_3: member_3, character: character} do
      conn = authenticated_conn(member_2)

      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share/#{member_3.id}")
      assert_unauthorized_response(conn, 403)
    end

    test "admin can unshare any entity", %{admin: admin, member_2: member_2, character: character} do
      conn = authenticated_conn(admin)

      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share/#{member_2.id}")
      assert_success_response(conn, 200)
    end

    test "game master can unshare any entity", %{game_master: game_master, member_2: member_2, character: character} do
      conn = authenticated_conn(game_master)

      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share/#{member_2.id}")
      assert_success_response(conn, 200)
    end

    test "unshare non-existent share returns success", %{member_1: member_1, member_3: member_3, character: character} do
      conn = authenticated_conn(member_1)

      # Try to unshare member_3 who was never shared with
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/share/#{member_3.id}")
      assert_success_response(conn, 200)
    end
  end

  describe "list shares tests" do
    setup %{member_1: member_1, member_2: member_2, member_3: member_3, test_game: game} do
      character = create_entity_for_user(:character, member_1, game, "private")
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_2, "editor")
      {:ok, _} = share_entity_with_user(:character, character, member_1, member_3, "viewer")
      %{character: character}
    end

    test "owner can list shares", %{member_1: member_1, member_2: member_2, member_3: member_3, character: character} do
      conn = authenticated_conn(member_1)

      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)

      shares = json_response(conn, 200)["data"]
      assert length(shares) == 2

      # Check that both shares are present
      user_ids = Enum.map(shares, & &1["user_id"])
      assert member_2.id in user_ids
      assert member_3.id in user_ids
    end

    test "member with editor share can list shares", %{member_2: member_2, character: character} do
      conn = authenticated_conn(member_2)

      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)
    end

    test "member with viewer share can list shares", %{member_3: member_3, character: character} do
      conn = authenticated_conn(member_3)

      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)
    end

    test "member without access cannot list shares", %{member_1: member_1, member_2: member_2, test_game: game} do
      # Create a private character with no shares for member_2
      private_character = create_entity_for_user(:character, member_1, game, "private")

      conn = authenticated_conn(member_2)

      conn = get(conn, ~p"/api/games/#{private_character.game_id}/characters/#{private_character.id}/shares")
      assert_unauthorized_response(conn, 403)
    end

    test "admin can list shares", %{admin: admin, character: character} do
      conn = authenticated_conn(admin)

      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)
    end

    test "game master can list shares", %{game_master: game_master, character: character} do
      conn = authenticated_conn(game_master)

      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)
    end

    test "list shares for entity with no shares returns empty list", %{member_1: member_1, test_game: game} do
      character = create_entity_for_user(:character, member_1, game, "private")

      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/shares")
      assert_success_response(conn, 200)

      shares = json_response(conn, 200)["data"]
      assert shares == []
    end
  end

  describe "update visibility tests" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      character = create_entity_for_user(:character, member_1, game, "private")
      %{character: character}
    end

    test "owner can update visibility to viewable", %{member_1: member_1, character: character} do
      conn = authenticated_conn(member_1)

      visibility_attrs = %{"visibility" => "viewable"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert_success_response(conn, 200)

      response_data = json_response(conn, 200)["data"]
      assert response_data["visibility"] == "viewable"
    end

    test "owner can update visibility to editable", %{member_1: member_1, character: character} do
      conn = authenticated_conn(member_1)

      visibility_attrs = %{"visibility" => "editable"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert_success_response(conn, 200)

      response_data = json_response(conn, 200)["data"]
      assert response_data["visibility"] == "editable"
    end

    test "owner can update visibility back to private", %{member_1: member_1, character: character, test_game: game} do
      # First make it viewable
      viewable_character = create_entity_for_user(:character, member_1, game, "viewable")

      conn = authenticated_conn(member_1)
      visibility_attrs = %{"visibility" => "private"}
      conn = patch(conn, ~p"/api/games/#{viewable_character.game_id}/characters/#{viewable_character.id}/visibility", visibility_attrs)
      assert_success_response(conn, 200)

      response_data = json_response(conn, 200)["data"]
      assert response_data["visibility"] == "private"
    end

    test "non-owner cannot update visibility", %{member_2: member_2, character: character} do
      conn = authenticated_conn(member_2)

      visibility_attrs = %{"visibility" => "viewable"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert_not_found_response(conn)
    end

    test "admin can update visibility", %{admin: admin, character: character} do
      conn = authenticated_conn(admin)

      visibility_attrs = %{"visibility" => "viewable"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can update visibility", %{game_master: game_master, character: character} do
      conn = authenticated_conn(game_master)

      visibility_attrs = %{"visibility" => "editable"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert_success_response(conn, 200)
    end

    test "invalid visibility value returns error", %{member_1: member_1, character: character} do
      conn = authenticated_conn(member_1)

      visibility_attrs = %{"visibility" => "invalid"}
      conn = patch(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}/visibility", visibility_attrs)
      assert conn.status == 422  # Unprocessable Entity
    end
  end
end
