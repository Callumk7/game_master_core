defmodule GameMasterCoreWeb.QuestAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "admin role permissions" do
    setup %{admin: admin, test_game: game} do
      private_quest = create_entity_for_user(:quest, admin, game, "private")
      viewable_quest = create_entity_for_user(:quest, admin, game, "viewable")
      editable_quest = create_entity_for_user(:quest, admin, game, "editable")

      %{
        private_quest: private_quest,
        viewable_quest: viewable_quest,
        editable_quest: editable_quest
      }
    end

    test "admin can view private quest", %{admin: admin, private_quest: quest} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update private quest", %{admin: admin, private_quest: quest} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete private quest", %{admin: admin, private_quest: quest} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "admin can view viewable quest", %{admin: admin, viewable_quest: quest} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update viewable quest", %{admin: admin, viewable_quest: quest} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete viewable quest", %{admin: admin, viewable_quest: quest} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "admin can view editable quest", %{admin: admin, editable_quest: quest} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update editable quest", %{admin: admin, editable_quest: quest} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete editable quest", %{admin: admin, editable_quest: quest} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end
  end

  describe "game master role permissions" do
    setup %{member_1: member_1, game_master: game_master, test_game: game} do
      private_quest = create_entity_for_user(:quest, member_1, game, "private")
      viewable_quest = create_entity_for_user(:quest, member_1, game, "viewable")
      editable_quest = create_entity_for_user(:quest, member_1, game, "editable")

      %{
        private_quest: private_quest,
        viewable_quest: viewable_quest,
        editable_quest: editable_quest
      }
    end

    test "game master can view private quest they don't own", %{game_master: game_master, private_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update private quest they don't own", %{game_master: game_master, private_quest: quest} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete private quest they don't own", %{game_master: game_master, private_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "game master can view viewable quest", %{game_master: game_master, viewable_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update viewable quest they don't own", %{game_master: game_master, viewable_quest: quest} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete viewable quest they don't own", %{game_master: game_master, viewable_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "game master can view editable quest", %{game_master: game_master, editable_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update editable quest they don't own", %{game_master: game_master, editable_quest: quest} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete editable quest they don't own", %{game_master: game_master, editable_quest: quest} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end
  end

  describe "entity owner permissions" do
    setup %{member_1: member_1, test_game: game} do
      private_quest = create_entity_for_user(:quest, member_1, game, "private")
      viewable_quest = create_entity_for_user(:quest, member_1, game, "viewable")
      editable_quest = create_entity_for_user(:quest, member_1, game, "editable")

      %{
        private_quest: private_quest,
        viewable_quest: viewable_quest,
        editable_quest: editable_quest
      }
    end

    test "owner can view own private quest", %{member_1: member_1, private_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own private quest", %{member_1: member_1, private_quest: quest} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own private quest", %{member_1: member_1, private_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "owner can view own viewable quest", %{member_1: member_1, viewable_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own viewable quest", %{member_1: member_1, viewable_quest: quest} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own viewable quest", %{member_1: member_1, viewable_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end

    test "owner can view own editable quest", %{member_1: member_1, editable_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own editable quest", %{member_1: member_1, editable_quest: quest} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own editable quest", %{member_1: member_1, editable_quest: quest} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert conn.status == 204
    end
  end

  describe "member access to private quests" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      private_quest = create_entity_for_user(:quest, member_1, game, "private")
      %{private_quest: private_quest}
    end

    test "member cannot view another member's private quest", %{member_2: member_2, private_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private quest", %{member_2: member_2, private_quest: quest} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private quest", %{member_2: member_2, private_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end
  end

  describe "member access to viewable quests" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      viewable_quest = create_entity_for_user(:quest, member_1, game, "viewable")
      %{viewable_quest: viewable_quest}
    end

    test "member can view another member's viewable quest", %{member_2: member_2, viewable_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "member cannot update another member's viewable quest", %{member_2: member_2, viewable_quest: quest} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable quest", %{member_2: member_2, viewable_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "member access to editable quests" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      editable_quest = create_entity_for_user(:quest, member_1, game, "editable")
      %{editable_quest: editable_quest}
    end

    test "member can view another member's editable quest", %{member_2: member_2, editable_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_success_response(conn, 200)
    end

    test "member can update another member's editable quest", %{member_2: member_2, editable_quest: quest} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Updated by Member"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "member cannot delete another member's editable quest", %{member_2: member_2, editable_quest: quest} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "non-member access" do
    setup %{member_1: member_1, non_member: non_member, test_game: game} do
      private_quest = create_entity_for_user(:quest, member_1, game, "private")
      viewable_quest = create_entity_for_user(:quest, member_1, game, "viewable")
      editable_quest = create_entity_for_user(:quest, member_1, game, "editable")

      %{
        private_quest: private_quest,
        viewable_quest: viewable_quest,
        editable_quest: editable_quest
      }
    end

    test "non-member cannot view private quest", %{non_member: non_member, private_quest: quest} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable quest", %{non_member: non_member, viewable_quest: quest} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable quest", %{non_member: non_member, editable_quest: quest} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot update any quest", %{non_member: non_member, editable_quest: quest} do
      conn = authenticated_conn(non_member)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any quest", %{non_member: non_member, editable_quest: quest} do
      conn = authenticated_conn(non_member)
      conn = delete(conn, ~p"/api/games/#{quest.game_id}/quests/#{quest.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot create quest", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)
      create_attrs = %{"name" => "Should not create", "content" => "content"}
      conn = post(conn, ~p"/api/games/#{game.id}/quests", create_attrs)
      assert_not_found_response(conn)
    end
  end
end
