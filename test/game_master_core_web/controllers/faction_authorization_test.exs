defmodule GameMasterCoreWeb.FactionAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "admin role permissions" do
    setup %{admin: admin, test_game: game} do
      private_faction = create_entity_for_user(:faction, admin, game, "private")
      viewable_faction = create_entity_for_user(:faction, admin, game, "viewable")
      editable_faction = create_entity_for_user(:faction, admin, game, "editable")

      %{
        private_faction: private_faction,
        viewable_faction: viewable_faction,
        editable_faction: editable_faction
      }
    end

    test "admin can view private faction", %{admin: admin, private_faction: faction} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update private faction", %{admin: admin, private_faction: faction} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete private faction", %{admin: admin, private_faction: faction} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "admin can view viewable faction", %{admin: admin, viewable_faction: faction} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update viewable faction", %{admin: admin, viewable_faction: faction} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete viewable faction", %{admin: admin, viewable_faction: faction} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "admin can view editable faction", %{admin: admin, editable_faction: faction} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update editable faction", %{admin: admin, editable_faction: faction} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete editable faction", %{admin: admin, editable_faction: faction} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end
  end

  describe "game master role permissions" do
    setup %{member_1: member_1, game_master: game_master, test_game: game} do
      private_faction = create_entity_for_user(:faction, member_1, game, "private")
      viewable_faction = create_entity_for_user(:faction, member_1, game, "viewable")
      editable_faction = create_entity_for_user(:faction, member_1, game, "editable")

      %{
        private_faction: private_faction,
        viewable_faction: viewable_faction,
        editable_faction: editable_faction
      }
    end

    test "game master can view private faction they don't own", %{game_master: game_master, private_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update private faction they don't own", %{game_master: game_master, private_faction: faction} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete private faction they don't own", %{game_master: game_master, private_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "game master can view viewable faction", %{game_master: game_master, viewable_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update viewable faction they don't own", %{game_master: game_master, viewable_faction: faction} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete viewable faction they don't own", %{game_master: game_master, viewable_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "game master can view editable faction", %{game_master: game_master, editable_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update editable faction they don't own", %{game_master: game_master, editable_faction: faction} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete editable faction they don't own", %{game_master: game_master, editable_faction: faction} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end
  end

  describe "entity owner permissions" do
    setup %{member_1: member_1, test_game: game} do
      private_faction = create_entity_for_user(:faction, member_1, game, "private")
      viewable_faction = create_entity_for_user(:faction, member_1, game, "viewable")
      editable_faction = create_entity_for_user(:faction, member_1, game, "editable")

      %{
        private_faction: private_faction,
        viewable_faction: viewable_faction,
        editable_faction: editable_faction
      }
    end

    test "owner can view own private faction", %{member_1: member_1, private_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own private faction", %{member_1: member_1, private_faction: faction} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own private faction", %{member_1: member_1, private_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "owner can view own viewable faction", %{member_1: member_1, viewable_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own viewable faction", %{member_1: member_1, viewable_faction: faction} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own viewable faction", %{member_1: member_1, viewable_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end

    test "owner can view own editable faction", %{member_1: member_1, editable_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own editable faction", %{member_1: member_1, editable_faction: faction} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own editable faction", %{member_1: member_1, editable_faction: faction} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert conn.status == 204
    end
  end

  describe "member access to private factions" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      private_faction = create_entity_for_user(:faction, member_1, game, "private")
      %{private_faction: private_faction}
    end

    test "member cannot view another member's private faction", %{member_2: member_2, private_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private faction", %{member_2: member_2, private_faction: faction} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private faction", %{member_2: member_2, private_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end
  end

  describe "member access to viewable factions" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      viewable_faction = create_entity_for_user(:faction, member_1, game, "viewable")
      %{viewable_faction: viewable_faction}
    end

    test "member can view another member's viewable faction", %{member_2: member_2, viewable_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "member cannot update another member's viewable faction", %{member_2: member_2, viewable_faction: faction} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable faction", %{member_2: member_2, viewable_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "member access to editable factions" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      editable_faction = create_entity_for_user(:faction, member_1, game, "editable")
      %{editable_faction: editable_faction}
    end

    test "member can view another member's editable faction", %{member_2: member_2, editable_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_success_response(conn, 200)
    end

    test "member can update another member's editable faction", %{member_2: member_2, editable_faction: faction} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Updated by Member"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "member cannot delete another member's editable faction", %{member_2: member_2, editable_faction: faction} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "non-member access" do
    setup %{member_1: member_1, non_member: non_member, test_game: game} do
      private_faction = create_entity_for_user(:faction, member_1, game, "private")
      viewable_faction = create_entity_for_user(:faction, member_1, game, "viewable")
      editable_faction = create_entity_for_user(:faction, member_1, game, "editable")

      %{
        private_faction: private_faction,
        viewable_faction: viewable_faction,
        editable_faction: editable_faction
      }
    end

    test "non-member cannot view private faction", %{non_member: non_member, private_faction: faction} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable faction", %{non_member: non_member, viewable_faction: faction} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable faction", %{non_member: non_member, editable_faction: faction} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot update any faction", %{non_member: non_member, editable_faction: faction} do
      conn = authenticated_conn(non_member)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any faction", %{non_member: non_member, editable_faction: faction} do
      conn = authenticated_conn(non_member)
      conn = delete(conn, ~p"/api/games/#{faction.game_id}/factions/#{faction.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot create faction", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)
      create_attrs = %{"name" => "Should not create", "content" => "content"}
      conn = post(conn, ~p"/api/games/#{game.id}/factions", create_attrs)
      assert_not_found_response(conn)
    end
  end
end
