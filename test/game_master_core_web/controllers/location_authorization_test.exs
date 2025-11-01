defmodule GameMasterCoreWeb.LocationAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "admin role permissions" do
    setup %{admin: admin, test_game: game} do
      private_location = create_entity_for_user(:location, admin, game, "private")
      viewable_location = create_entity_for_user(:location, admin, game, "viewable")
      editable_location = create_entity_for_user(:location, admin, game, "editable")

      %{
        private_location: private_location,
        viewable_location: viewable_location,
        editable_location: editable_location
      }
    end

    test "admin can view private location", %{admin: admin, private_location: location} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update private location", %{admin: admin, private_location: location} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete private location", %{admin: admin, private_location: location} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "admin can view viewable location", %{admin: admin, viewable_location: location} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update viewable location", %{admin: admin, viewable_location: location} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete viewable location", %{admin: admin, viewable_location: location} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "admin can view editable location", %{admin: admin, editable_location: location} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update editable location", %{admin: admin, editable_location: location} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete editable location", %{admin: admin, editable_location: location} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end
  end

  describe "game master role permissions" do
    setup %{member_1: member_1, game_master: game_master, test_game: game} do
      private_location = create_entity_for_user(:location, member_1, game, "private")
      viewable_location = create_entity_for_user(:location, member_1, game, "viewable")
      editable_location = create_entity_for_user(:location, member_1, game, "editable")

      %{
        private_location: private_location,
        viewable_location: viewable_location,
        editable_location: editable_location
      }
    end

    test "game master can view private location they don't own", %{game_master: game_master, private_location: location} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update private location they don't own", %{game_master: game_master, private_location: location} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete private location they don't own", %{game_master: game_master, private_location: location} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "game master can view viewable location", %{game_master: game_master, viewable_location: location} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update viewable location they don't own", %{game_master: game_master, viewable_location: location} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete viewable location they don't own", %{game_master: game_master, viewable_location: location} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "game master can view editable location", %{game_master: game_master, editable_location: location} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update editable location they don't own", %{game_master: game_master, editable_location: location} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete editable location they don't own", %{game_master: game_master, editable_location: location} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end
  end

  describe "entity owner permissions" do
    setup %{member_1: member_1, test_game: game} do
      private_location = create_entity_for_user(:location, member_1, game, "private")
      viewable_location = create_entity_for_user(:location, member_1, game, "viewable")
      editable_location = create_entity_for_user(:location, member_1, game, "editable")

      %{
        private_location: private_location,
        viewable_location: viewable_location,
        editable_location: editable_location
      }
    end

    test "owner can view own private location", %{member_1: member_1, private_location: location} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own private location", %{member_1: member_1, private_location: location} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own private location", %{member_1: member_1, private_location: location} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "owner can view own viewable location", %{member_1: member_1, viewable_location: location} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own viewable location", %{member_1: member_1, viewable_location: location} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own viewable location", %{member_1: member_1, viewable_location: location} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end

    test "owner can view own editable location", %{member_1: member_1, editable_location: location} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own editable location", %{member_1: member_1, editable_location: location} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own editable location", %{member_1: member_1, editable_location: location} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert conn.status == 204
    end
  end

  describe "member access to private locations" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      private_location = create_entity_for_user(:location, member_1, game, "private")
      %{private_location: private_location}
    end

    test "member cannot view another member's private location", %{member_2: member_2, private_location: location} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private location", %{member_2: member_2, private_location: location} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private location", %{member_2: member_2, private_location: location} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end
  end

  describe "member access to viewable locations" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      viewable_location = create_entity_for_user(:location, member_1, game, "viewable")
      %{viewable_location: viewable_location}
    end

    test "member can view another member's viewable location", %{member_2: member_2, viewable_location: location} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "member cannot update another member's viewable location", %{member_2: member_2, viewable_location: location} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable location", %{member_2: member_2, viewable_location: location} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "member access to editable locations" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      editable_location = create_entity_for_user(:location, member_1, game, "editable")
      %{editable_location: editable_location}
    end

    test "member can view another member's editable location", %{member_2: member_2, editable_location: location} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_success_response(conn, 200)
    end

    test "member can update another member's editable location", %{member_2: member_2, editable_location: location} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Updated by Member"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "member cannot delete another member's editable location", %{member_2: member_2, editable_location: location} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "non-member access" do
    setup %{member_1: member_1, non_member: non_member, test_game: game} do
      private_location = create_entity_for_user(:location, member_1, game, "private")
      viewable_location = create_entity_for_user(:location, member_1, game, "viewable")
      editable_location = create_entity_for_user(:location, member_1, game, "editable")

      %{
        private_location: private_location,
        viewable_location: viewable_location,
        editable_location: editable_location
      }
    end

    test "non-member cannot view private location", %{non_member: non_member, private_location: location} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable location", %{non_member: non_member, viewable_location: location} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable location", %{non_member: non_member, editable_location: location} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot update any location", %{non_member: non_member, editable_location: location} do
      conn = authenticated_conn(non_member)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any location", %{non_member: non_member, editable_location: location} do
      conn = authenticated_conn(non_member)
      conn = delete(conn, ~p"/api/games/#{location.game_id}/locations/#{location.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot create location", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)
      create_attrs = %{"name" => "Should not create", "content" => "content"}
      conn = post(conn, ~p"/api/games/#{game.id}/locations", create_attrs)
      assert_not_found_response(conn)
    end
  end
end
