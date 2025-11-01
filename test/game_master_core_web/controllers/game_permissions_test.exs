defmodule GameMasterCoreWeb.GamePermissionsTest do
  use GameMasterCoreWeb.ConnCase, async: true

  import GameMasterCoreWeb.AuthorizationTestHelpers

  alias GameMasterCore.{Games, Repo}

  setup do
    setup_test_game_and_users()
  end

  # ============================================================================
  # Manage Game Permission Tests
  # ============================================================================

  describe "PUT /api/games/:id - manage game permission" do
    test "admin can update game settings", %{conn: conn, game: game, admin: admin} do
      conn = authenticate_api_user(conn, admin)

      conn = put(conn, "/api/games/#{game.id}", %{
        game: %{name: "Updated Game Name"}
      })

      assert_success_response(conn, 200)
      response = json_response(conn, 200)
      assert response["data"]["name"] == "Updated Game Name"
    end

    test "game master cannot update game settings", %{conn: conn, game: game, game_master: gm} do
      conn = authenticate_api_user(conn, gm)

      conn = put(conn, "/api/games/#{game.id}", %{
        game: %{name: "Updated Game Name"}
      })

      assert_unauthorized_response(conn, 403)
    end

    test "member cannot update game settings", %{conn: conn, game: game, member_1: member} do
      conn = authenticate_api_user(conn, member)

      conn = put(conn, "/api/games/#{game.id}", %{
        game: %{name: "Updated Game Name"}
      })

      assert_unauthorized_response(conn, 403)
    end

    test "non-member cannot access game", %{conn: conn, game: game, non_member: non_member} do
      conn = authenticate_api_user(conn, non_member)

      conn = put(conn, "/api/games/#{game.id}", %{
        game: %{name: "Updated Game Name"}
      })

      assert_not_found_response(conn)
    end
  end

  describe "DELETE /api/games/:id - delete game permission" do
    test "admin can delete game", %{conn: conn, admin: admin} do
      # Create a separate game for deletion
      admin_scope = GameMasterCore.Accounts.Scope.for_user(admin)
      {:ok, game_to_delete} = Games.create_game(admin_scope, %{
        name: "Game to Delete",
        content: "Content",
        setting: "Setting"
      })

      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, "/api/games/#{game_to_delete.id}")

      assert conn.status in [200, 204]

      # Verify game is deleted
      assert Games.fetch_game(admin_scope, game_to_delete.id) == {:error, :not_found}
    end

    test "game master cannot delete game", %{conn: conn, game: game, game_master: gm, admin: admin} do
      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, "/api/games/#{game.id}")

      assert_unauthorized_response(conn, 403)

      # Verify game still exists
      admin_scope = GameMasterCore.Accounts.Scope.for_user(admin)
      assert {:ok, _} = Games.fetch_game(admin_scope, game.id)
    end

    test "member cannot delete game", %{conn: conn, game: game, member_1: member, admin: admin} do
      conn = authenticate_api_user(conn, member)
      conn = delete(conn, "/api/games/#{game.id}")

      assert_unauthorized_response(conn, 403)

      # Verify game still exists
      admin_scope = GameMasterCore.Accounts.Scope.for_user(admin)
      assert {:ok, _} = Games.fetch_game(admin_scope, game.id)
    end
  end

  # ============================================================================
  # Manage Members Permission Tests
  # ============================================================================

  # NOTE: These tests require member management API endpoints to be implemented
  # The endpoints POST/DELETE /api/games/:id/members and PUT /api/games/:id/members/:user_id/role
  # are not yet implemented in the router/controller

  describe "POST /api/games/:id/members - add member permission" do
    @describetag :skip
    test "admin can add member to game", %{conn: conn, game: game, admin: admin} do
      new_user = GameMasterCore.AccountsFixtures.user_fixture(%{
        email: "newuser@test.com",
        username: "newuser"
      })

      conn = authenticate_api_user(conn, admin)
      conn = post(conn, "/api/games/#{game.id}/members", %{
        user_id: new_user.id,
        role: "member"
      })

      assert conn.status in [200, 201]

      # Verify member was added
      admin_scope = GameMasterCore.Accounts.Scope.for_user(admin) |> GameMasterCore.Accounts.Scope.put_game(game)
      members = Games.list_members(admin_scope, game)
      assert Enum.any?(members, fn m -> m.user_id == new_user.id end)
    end

    test "game master cannot add member", %{conn: conn, game: game, game_master: gm} do
      new_user = GameMasterCore.AccountsFixtures.user_fixture(%{
        email: "newuser2@test.com",
        username: "newuser2"
      })

      conn = authenticate_api_user(conn, gm)
      conn = post(conn, "/api/games/#{game.id}/members", %{
        user_id: new_user.id,
        role: "member"
      })

      assert_unauthorized_response(conn, 403)
    end

    test "member cannot add member", %{conn: conn, game: game, member_1: member} do
      new_user = GameMasterCore.AccountsFixtures.user_fixture(%{
        email: "newuser3@test.com",
        username: "newuser3"
      })

      conn = authenticate_api_user(conn, member)
      conn = post(conn, "/api/games/#{game.id}/members", %{
        user_id: new_user.id,
        role: "member"
      })

      assert_unauthorized_response(conn, 403)
    end
  end

  describe "DELETE /api/games/:id/members/:user_id - remove member permission" do
    @describetag :skip
    test "admin can remove member from game", %{
      conn: conn,
      game: game,
      admin: admin,
      member_1: member_to_remove
    } do
      conn = authenticate_api_user(conn, admin)
      conn = delete(conn, "/api/games/#{game.id}/members/#{member_to_remove.id}")

      assert conn.status in [200, 204]

      # Verify member was removed
      admin_scope = GameMasterCore.Accounts.Scope.for_user(admin) |> GameMasterCore.Accounts.Scope.put_game(game)
      members = Games.list_members(admin_scope, game)
      refute Enum.any?(members, fn m -> m.user_id == member_to_remove.id end)
    end

    test "game master cannot remove member", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_1: member
    } do
      conn = authenticate_api_user(conn, gm)
      conn = delete(conn, "/api/games/#{game.id}/members/#{member.id}")

      assert_unauthorized_response(conn, 403)
    end

    test "member cannot remove member", %{
      conn: conn,
      game: game,
      member_1: member,
      member_2: other_member
    } do
      conn = authenticate_api_user(conn, member)
      conn = delete(conn, "/api/games/#{game.id}/members/#{other_member.id}")

      assert_unauthorized_response(conn, 403)
    end
  end

  describe "PUT /api/games/:id/members/:user_id/role - change member role permission" do
    @describetag :skip
    test "admin can change member role", %{
      conn: conn,
      game: game,
      admin: admin,
      member_1: member
    } do
      conn = authenticate_api_user(conn, admin)
      conn = put(conn, "/api/games/#{game.id}/members/#{member.id}/role", %{
        role: "game_master"
      })

      assert_success_response(conn, 200)

      # Verify role was changed
      membership = Repo.get_by(GameMasterCore.Games.GameMembership, game_id: game.id, user_id: member.id)
      assert membership.role == "game_master"
    end

    test "game master cannot change member role", %{
      conn: conn,
      game: game,
      game_master: gm,
      member_1: member
    } do
      conn = authenticate_api_user(conn, gm)
      conn = put(conn, "/api/games/#{game.id}/members/#{member.id}/role", %{
        role: "game_master"
      })

      assert_unauthorized_response(conn, 403)
    end

    test "member cannot change member role", %{
      conn: conn,
      game: game,
      member_1: member,
      member_2: other_member
    } do
      conn = authenticate_api_user(conn, member)
      conn = put(conn, "/api/games/#{game.id}/members/#{other_member.id}/role", %{
        role: "game_master"
      })

      assert_unauthorized_response(conn, 403)
    end
  end
end
