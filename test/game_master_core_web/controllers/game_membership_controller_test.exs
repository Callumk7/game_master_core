defmodule GameMasterCoreWeb.GameMembershipControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures

  setup :register_and_log_in_user

  setup %{conn: conn, user: user} do
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn}
  end

  describe "membership management" do
    test "add member to game", %{conn: conn, scope: scope} do
      game = game_fixture(scope)
      other_user = user_fixture()

      conn = post(conn, ~p"/api/games/#{game.id}/members", user_id: other_user.id, role: "member")
      assert response(conn, 201)
    end

    test "remove member from game", %{conn: conn, scope: scope} do
      game = game_fixture(scope)
      other_user = user_fixture()

      scope_with_game = GameMasterCore.Accounts.Scope.put_game(scope, game)
      {:ok, _membership} = GameMasterCore.Games.add_member(scope_with_game, game, other_user.id)

      conn = delete(conn, ~p"/api/games/#{game.id}/members/#{other_user.id}")
      assert response(conn, 204)
    end

    test "list members of game", %{conn: conn, scope: scope} do
      game = game_fixture(scope)
      other_user = user_fixture()

      scope_with_game = GameMasterCore.Accounts.Scope.put_game(scope, game)
      {:ok, _membership} = GameMasterCore.Games.add_member(scope_with_game, game, other_user.id)

      conn = get(conn, ~p"/api/games/#{game.id}/members")
      assert %{"data" => [member]} = json_response(conn, 200)
      assert member["user_id"] == other_user.id
      assert member["role"] == "member"
    end

    test "only owner can add members", %{scope: owner_scope} do
      game = game_fixture(owner_scope)
      other_user = user_fixture()
      member_user = user_fixture()

      scope_with_game = GameMasterCore.Accounts.Scope.put_game(owner_scope, game)
      {:ok, _membership} = GameMasterCore.Games.add_member(scope_with_game, game, member_user.id)

      conn = authenticate_api_user(build_conn(), member_user)

      conn = post(conn, ~p"/api/games/#{game.id}/members", user_id: other_user.id)
      assert response(conn, 403)
    end
  end
end
