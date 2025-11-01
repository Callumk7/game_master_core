defmodule GameMasterCoreWeb.CharacterAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "admin role permissions" do
    setup %{admin: admin, test_game: game} do
      # Create private character by member_1
      private_character = create_entity_for_user(:character, admin, game, "private")
      viewable_character = create_entity_for_user(:character, admin, game, "viewable")
      editable_character = create_entity_for_user(:character, admin, game, "editable")

      %{
        private_character: private_character,
        viewable_character: viewable_character,
        editable_character: editable_character
      }
    end

    test "admin can view private character", %{admin: admin, private_character: character} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update private character", %{admin: admin, private_character: character} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete private character", %{admin: admin, private_character: character} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "admin can view viewable character", %{admin: admin, viewable_character: character} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update viewable character", %{admin: admin, viewable_character: character} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete viewable character", %{admin: admin, viewable_character: character} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "admin can view editable character", %{admin: admin, editable_character: character} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update editable character", %{admin: admin, editable_character: character} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete editable character", %{admin: admin, editable_character: character} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end
  end

  describe "game master role permissions" do
    setup %{member_1: member_1, game_master: game_master, test_game: game} do
      # Create characters by member_1, test access by game_master
      private_character = create_entity_for_user(:character, member_1, game, "private")
      viewable_character = create_entity_for_user(:character, member_1, game, "viewable")
      editable_character = create_entity_for_user(:character, member_1, game, "editable")

      %{
        private_character: private_character,
        viewable_character: viewable_character,
        editable_character: editable_character
      }
    end

    test "game master can view private character they don't own", %{game_master: game_master, private_character: character} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update private character they don't own", %{game_master: game_master, private_character: character} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete private character they don't own", %{game_master: game_master, private_character: character} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "game master can view viewable character", %{game_master: game_master, viewable_character: character} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update viewable character they don't own", %{game_master: game_master, viewable_character: character} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete viewable character they don't own", %{game_master: game_master, viewable_character: character} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "game master can view editable character", %{game_master: game_master, editable_character: character} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update editable character they don't own", %{game_master: game_master, editable_character: character} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete editable character they don't own", %{game_master: game_master, editable_character: character} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end
  end

  describe "entity owner permissions" do
    setup %{member_1: member_1, test_game: game} do
      # member_1 creates their own characters
      private_character = create_entity_for_user(:character, member_1, game, "private")
      viewable_character = create_entity_for_user(:character, member_1, game, "viewable")
      editable_character = create_entity_for_user(:character, member_1, game, "editable")

      %{
        private_character: private_character,
        viewable_character: viewable_character,
        editable_character: editable_character
      }
    end

    test "owner can view own private character", %{member_1: member_1, private_character: character} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own private character", %{member_1: member_1, private_character: character} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own private character", %{member_1: member_1, private_character: character} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "owner can view own viewable character", %{member_1: member_1, viewable_character: character} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own viewable character", %{member_1: member_1, viewable_character: character} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own viewable character", %{member_1: member_1, viewable_character: character} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end

    test "owner can view own editable character", %{member_1: member_1, editable_character: character} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own editable character", %{member_1: member_1, editable_character: character} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own editable character", %{member_1: member_1, editable_character: character} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert conn.status == 204
    end
  end

  describe "member access to private entities" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      # member_1 creates private character, member_2 tries to access
      private_character = create_entity_for_user(:character, member_1, game, "private")
      %{private_character: private_character}
    end

    test "member cannot view another member's private character", %{member_2: member_2, private_character: character} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private character", %{member_2: member_2, private_character: character} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private character", %{member_2: member_2, private_character: character} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end
  end

  describe "member access to viewable entities" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      # member_1 creates viewable character, member_2 tries to access
      viewable_character = create_entity_for_user(:character, member_1, game, "viewable")
      %{viewable_character: viewable_character}
    end

    test "member can view another member's viewable character", %{member_2: member_2, viewable_character: character} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "member cannot update another member's viewable character", %{member_2: member_2, viewable_character: character} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable character", %{member_2: member_2, viewable_character: character} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "member access to editable entities" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      # member_1 creates editable character, member_2 tries to access
      editable_character = create_entity_for_user(:character, member_1, game, "editable")
      %{editable_character: editable_character}
    end

    test "member can view another member's editable character", %{member_2: member_2, editable_character: character} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_success_response(conn, 200)
    end

    test "member can update another member's editable character", %{member_2: member_2, editable_character: character} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Updated by Member"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "member cannot delete another member's editable character", %{member_2: member_2, editable_character: character} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "non-member access" do
    setup %{member_1: member_1, non_member: non_member, test_game: game} do
      # member_1 creates character, non_member tries to access
      private_character = create_entity_for_user(:character, member_1, game, "private")
      viewable_character = create_entity_for_user(:character, member_1, game, "viewable")
      editable_character = create_entity_for_user(:character, member_1, game, "editable")

      %{
        private_character: private_character,
        viewable_character: viewable_character,
        editable_character: editable_character
      }
    end

    test "non-member cannot view private character", %{non_member: non_member, private_character: character} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable character", %{non_member: non_member, viewable_character: character} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable character", %{non_member: non_member, editable_character: character} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot update any character", %{non_member: non_member, editable_character: character} do
      conn = authenticated_conn(non_member)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any character", %{non_member: non_member, editable_character: character} do
      conn = authenticated_conn(non_member)
      conn = delete(conn, ~p"/api/games/#{character.game_id}/characters/#{character.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot create character", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)
      create_attrs = %{"name" => "Should not create", "content" => "content"}
      conn = post(conn, ~p"/api/games/#{game.id}/characters", create_attrs)
      assert_not_found_response(conn)
    end
  end
end
