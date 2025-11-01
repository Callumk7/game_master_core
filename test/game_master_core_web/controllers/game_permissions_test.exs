defmodule GameMasterCoreWeb.GamePermissionsTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  setup :setup_test_users_and_game

  describe "manage game permission" do
    test "admin can update game settings", %{admin: admin, test_game: game} do
      conn = authenticated_conn(admin)

      update_attrs = %{
        "game" => %{
          "name" => "Updated Game Name",
          "content" => "Updated content"
        }
      }

      conn = put(conn, ~p"/api/games/#{game.id}", update_attrs)
      assert_success_response(conn, 200)

      # Verify the game was updated
      response_data = json_response(conn, 200)["data"]
      assert response_data["name"] == "Updated Game Name"
      assert response_data["content"] == "Updated content"
    end

    test "admin can delete game", %{admin: admin, test_game: game} do
      conn = authenticated_conn(admin)

      conn = delete(conn, ~p"/api/games/#{game.id}")
      assert conn.status == 204
    end

    test "game master cannot update game settings", %{game_master: game_master, test_game: game} do
      conn = authenticated_conn(game_master)

      update_attrs = %{"game" => %{"name" => "Should Not Update"}}

      conn = put(conn, ~p"/api/games/#{game.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "game master cannot delete game", %{game_master: game_master, test_game: game} do
      conn = authenticated_conn(game_master)

      conn = delete(conn, ~p"/api/games/#{game.id}")
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot update game settings", %{member_1: member, test_game: game} do
      conn = authenticated_conn(member)

      update_attrs = %{"game" => %{"name" => "Should Not Update"}}

      conn = put(conn, ~p"/api/games/#{game.id}", update_attrs)
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot delete game", %{member_1: member, test_game: game} do
      conn = authenticated_conn(member)

      conn = delete(conn, ~p"/api/games/#{game.id}")
      assert_unauthorized_response(conn, 403)
    end

    test "non-member cannot access game", %{non_member: non_member, test_game: game} do
      conn = authenticated_conn(non_member)

      conn = get(conn, ~p"/api/games/#{game.id}")
      assert_not_found_response(conn)
    end
  end

  describe "manage members permission" do
    test "admin can add member to game", %{admin: admin, test_game: game, non_member: new_member} do
      conn = authenticated_conn(admin)

      conn = post(conn, ~p"/api/games/#{game.id}/members", %{"user_id" => new_member.id, "role" => "member"})
      assert_success_response(conn, 201)
    end

    test "admin can remove member from game", %{admin: admin, test_game: game, member_1: member_to_remove} do
      conn = authenticated_conn(admin)

      conn = delete(conn, ~p"/api/games/#{game.id}/members/#{member_to_remove.id}")
      assert conn.status == 204
    end

    test "admin can change member role", %{admin: admin, test_game: game, member_1: member} do
      conn = authenticated_conn(admin)

      conn = patch(conn, ~p"/api/games/#{game.id}/members/#{member.id}/role", %{"role" => "game_master"})
      assert_success_response(conn, 200)

      response_data = json_response(conn, 200)["data"]
      assert response_data["role"] == "game_master"
    end

    test "admin cannot change own role if only admin", %{admin: admin, test_game: game} do
      conn = authenticated_conn(admin)

      conn = patch(conn, ~p"/api/games/#{game.id}/members/#{admin.id}/role", %{"role" => "member"})
      assert_unauthorized_response(conn, 403)
    end

    test "game master cannot add member", %{game_master: game_master, test_game: game, non_member: new_member} do
      conn = authenticated_conn(game_master)

      conn = post(conn, ~p"/api/games/#{game.id}/members", %{"user_id" => new_member.id, "role" => "member"})
      assert_unauthorized_response(conn, 403)
    end

    test "game master cannot remove member", %{game_master: game_master, test_game: game, member_1: member} do
      conn = authenticated_conn(game_master)

      conn = delete(conn, ~p"/api/games/#{game.id}/members/#{member.id}")
      assert_unauthorized_response(conn, 403)
    end

    test "game master cannot change member role", %{game_master: game_master, test_game: game, member_1: member} do
      conn = authenticated_conn(game_master)

      conn = patch(conn, ~p"/api/games/#{game.id}/members/#{member.id}/role", %{"role" => "game_master"})
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot add member", %{member_1: member, test_game: game, non_member: new_member} do
      conn = authenticated_conn(member)

      conn = post(conn, ~p"/api/games/#{game.id}/members", %{"user_id" => new_member.id, "role" => "member"})
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot remove member", %{member_1: member, test_game: game, member_2: member_to_remove} do
      conn = authenticated_conn(member)

      conn = delete(conn, ~p"/api/games/#{game.id}/members/#{member_to_remove.id}")
      assert_unauthorized_response(conn, 403)
    end

    test "member cannot change member role", %{member_1: member, test_game: game, member_2: member_to_change} do
      conn = authenticated_conn(member)

      conn = patch(conn, ~p"/api/games/#{game.id}/members/#{member_to_change.id}/role", %{"role" => "game_master"})
      assert_unauthorized_response(conn, 403)
    end
  end
end
