defmodule GameMasterCoreWeb.GameMembershipControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures

  setup :register_and_log_in_user

  setup %{conn: conn, user: user} do
    user_token = GameMasterCore.Accounts.create_user_api_token(user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user_token}")

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

      {:ok, _membership} = GameMasterCore.Games.add_member(scope, game, other_user.id)

      conn = delete(conn, ~p"/api/games/#{game.id}/members/#{other_user.id}")
      assert response(conn, 204)
    end

    test "list members of game", %{conn: conn, scope: scope} do
      game = game_fixture(scope)
      other_user = user_fixture()

      {:ok, _membership} = GameMasterCore.Games.add_member(scope, game, other_user.id)

      conn = get(conn, ~p"/api/games/#{game.id}/members")
      assert %{"data" => [member]} = json_response(conn, 200)
      assert member["user_id"] == other_user.id
      assert member["role"] == "member"
    end

    test "only owner can add members", %{scope: owner_scope} do
      game = game_fixture(owner_scope)
      other_user = user_fixture()
      member_user = user_fixture()

      {:ok, _membership} = GameMasterCore.Games.add_member(owner_scope, game, member_user.id)

      user_token = GameMasterCore.Accounts.create_user_api_token(member_user)

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{user_token}")

      conn = post(conn, ~p"/api/games/#{game.id}/members", user_id: other_user.id)
      assert response(conn, 403)
    end
  end
end
