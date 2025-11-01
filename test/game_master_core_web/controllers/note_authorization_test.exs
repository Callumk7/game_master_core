defmodule GameMasterCoreWeb.NoteAuthorizationTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "admin role permissions" do
    setup %{admin: admin, test_game: game} do
      private_note = create_entity_for_user(:note, admin, game, "private")
      viewable_note = create_entity_for_user(:note, admin, game, "viewable")
      editable_note = create_entity_for_user(:note, admin, game, "editable")

      %{
        private_note: private_note,
        viewable_note: viewable_note,
        editable_note: editable_note
      }
    end

    test "admin can view private note", %{admin: admin, private_note: note} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update private note", %{admin: admin, private_note: note} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete private note", %{admin: admin, private_note: note} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "admin can view viewable note", %{admin: admin, viewable_note: note} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update viewable note", %{admin: admin, viewable_note: note} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete viewable note", %{admin: admin, viewable_note: note} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "admin can view editable note", %{admin: admin, editable_note: note} do
      conn = authenticated_conn(admin)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "admin can update editable note", %{admin: admin, editable_note: note} do
      conn = authenticated_conn(admin)
      update_attrs = %{"name" => "Updated by Admin"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "admin can delete editable note", %{admin: admin, editable_note: note} do
      conn = authenticated_conn(admin)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end
  end

  describe "game master role permissions" do
    setup %{member_1: member_1, game_master: game_master, test_game: game} do
      private_note = create_entity_for_user(:note, member_1, game, "private")
      viewable_note = create_entity_for_user(:note, member_1, game, "viewable")
      editable_note = create_entity_for_user(:note, member_1, game, "editable")

      %{
        private_note: private_note,
        viewable_note: viewable_note,
        editable_note: editable_note
      }
    end

    test "game master can view private note they don't own", %{game_master: game_master, private_note: note} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update private note they don't own", %{game_master: game_master, private_note: note} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete private note they don't own", %{game_master: game_master, private_note: note} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "game master can view viewable note", %{game_master: game_master, viewable_note: note} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update viewable note they don't own", %{game_master: game_master, viewable_note: note} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete viewable note they don't own", %{game_master: game_master, viewable_note: note} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "game master can view editable note", %{game_master: game_master, editable_note: note} do
      conn = authenticated_conn(game_master)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "game master can update editable note they don't own", %{game_master: game_master, editable_note: note} do
      conn = authenticated_conn(game_master)
      update_attrs = %{"name" => "Updated by GM"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "game master can delete editable note they don't own", %{game_master: game_master, editable_note: note} do
      conn = authenticated_conn(game_master)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end
  end

  describe "entity owner permissions" do
    setup %{member_1: member_1, test_game: game} do
      private_note = create_entity_for_user(:note, member_1, game, "private")
      viewable_note = create_entity_for_user(:note, member_1, game, "viewable")
      editable_note = create_entity_for_user(:note, member_1, game, "editable")

      %{
        private_note: private_note,
        viewable_note: viewable_note,
        editable_note: editable_note
      }
    end

    test "owner can view own private note", %{member_1: member_1, private_note: note} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own private note", %{member_1: member_1, private_note: note} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own private note", %{member_1: member_1, private_note: note} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "owner can view own viewable note", %{member_1: member_1, viewable_note: note} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own viewable note", %{member_1: member_1, viewable_note: note} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own viewable note", %{member_1: member_1, viewable_note: note} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end

    test "owner can view own editable note", %{member_1: member_1, editable_note: note} do
      conn = authenticated_conn(member_1)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "owner can update own editable note", %{member_1: member_1, editable_note: note} do
      conn = authenticated_conn(member_1)
      update_attrs = %{"name" => "Updated by Owner"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "owner can delete own editable note", %{member_1: member_1, editable_note: note} do
      conn = authenticated_conn(member_1)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert conn.status == 204
    end
  end

  describe "member access to private notes" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      private_note = create_entity_for_user(:note, member_1, game, "private")
      %{private_note: private_note}
    end

    test "member cannot view another member's private note", %{member_2: member_2, private_note: note} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end

    test "member cannot update another member's private note", %{member_2: member_2, private_note: note} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "member cannot delete another member's private note", %{member_2: member_2, private_note: note} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end
  end

  describe "member access to viewable notes" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      viewable_note = create_entity_for_user(:note, member_1, game, "viewable")
      %{viewable_note: viewable_note}
    end

    test "member can view another member's viewable note", %{member_2: member_2, viewable_note: note} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "member cannot update another member's viewable note", %{member_2: member_2, viewable_note: note} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete another member's viewable note", %{member_2: member_2, viewable_note: note} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "member access to editable notes" do
    setup %{member_1: member_1, member_2: member_2, test_game: game} do
      editable_note = create_entity_for_user(:note, member_1, game, "editable")
      %{editable_note: editable_note}
    end

    test "member can view another member's editable note", %{member_2: member_2, editable_note: note} do
      conn = authenticated_conn(member_2)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_success_response(conn, 200)
    end

    test "member can update another member's editable note", %{member_2: member_2, editable_note: note} do
      conn = authenticated_conn(member_2)
      update_attrs = %{"name" => "Updated by Member"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_success_response(conn, 200)
    end

    test "member cannot delete another member's editable note", %{member_2: member_2, editable_note: note} do
      conn = authenticated_conn(member_2)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_unauthorized_response(conn, 403)
    end
  end

  describe "non-member access" do
    setup %{member_1: member_1, non_member: non_member, test_game: game} do
      private_note = create_entity_for_user(:note, member_1, game, "private")
      viewable_note = create_entity_for_user(:note, member_1, game, "viewable")
      editable_note = create_entity_for_user(:note, member_1, game, "editable")

      %{
        private_note: private_note,
        viewable_note: viewable_note,
        editable_note: editable_note
      }
    end

    test "non-member cannot view private note", %{non_member: non_member, private_note: note} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view viewable note", %{non_member: non_member, viewable_note: note} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot view editable note", %{non_member: non_member, editable_note: note} do
      conn = authenticated_conn(non_member)
      conn = get(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot update any note", %{non_member: non_member, editable_note: note} do
      conn = authenticated_conn(non_member)
      update_attrs = %{"name" => "Should not update"}
      conn = put(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}", update_attrs)
      assert_not_found_response(conn)
    end

    test "non-member cannot delete any note", %{non_member: non_member, editable_note: note} do
      conn = authenticated_conn(non_member)
      conn = delete(conn, ~p"/api/games/#{note.game_id}/notes/#{note.id}")
      assert_not_found_response(conn)
    end

    test "non-member cannot create note", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)
      create_attrs = %{"name" => "Should not create", "content" => "content"}
      conn = post(conn, ~p"/api/games/#{game.id}/notes", create_attrs)
      assert_not_found_response(conn)
    end
  end
end
