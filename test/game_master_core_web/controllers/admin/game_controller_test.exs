defmodule GameMasterCoreWeb.Admin.GameControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all games", %{conn: conn} do
      conn = get(conn, ~p"/admin/games")
      assert html_response(conn, 200) =~ "Listing Games"
    end
  end

  describe "new game" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/games/new")
      assert html_response(conn, 200) =~ "New Game"
    end
  end

  describe "create game" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/games", game: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/games/#{id}"

      conn = get(conn, ~p"/admin/games/#{id}")
      assert html_response(conn, 200) =~ "Game #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/games", game: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Game"
    end
  end

  describe "edit game" do
    setup [:create_game]

    test "renders form for editing chosen game", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/edit")
      assert html_response(conn, 200) =~ "Edit Game"
    end
  end

  describe "update game" do
    setup [:create_game]

    test "redirects when data is valid", %{conn: conn, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}", game: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/games/#{game}"

      conn = get(conn, ~p"/admin/games/#{game}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}", game: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Game"
    end
  end

  describe "delete game" do
    setup [:create_game]

    test "deletes chosen game", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/admin/games/#{game}")
      assert redirected_to(conn) == ~p"/admin/games"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/games/#{game}")
      end
    end
  end

  defp create_game(%{scope: scope}) do
    game = game_fixture(scope)

    %{game: game}
  end
end
