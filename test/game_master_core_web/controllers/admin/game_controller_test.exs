defmodule GameMasterCoreWeb.Admin.GameControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures

  @create_attrs %{name: "some name", content: "some content"}
  @update_attrs %{name: "some updated name", content: "some updated content"}
  @invalid_attrs %{name: nil, content: nil}

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

      conn = get(conn, ~p"/admin/games/#{game}")
      assert html_response(conn, 404)
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/admin/games/invalid")
      assert html_response(conn, 404)
    end

    test "show returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/admin/games/#{non_existent_id}")
      assert html_response(conn, 404)
    end

    test "edit returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/admin/games/invalid/edit")
      assert html_response(conn, 404)
    end

    test "edit returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/admin/games/#{non_existent_id}/edit")
      assert html_response(conn, 404)
    end

    test "update returns 404 for invalid game id format", %{conn: conn} do
      conn = put(conn, ~p"/admin/games/invalid", game: %{name: "test"})
      assert html_response(conn, 404)
    end

    test "update returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/admin/games/#{non_existent_id}", game: %{name: "test"})
      assert html_response(conn, 404)
    end

    test "delete returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/admin/games/invalid")
      assert html_response(conn, 404)
    end

    test "delete returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/admin/games/#{non_existent_id}")
      assert html_response(conn, 404)
    end

    test "list_members returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/admin/games/invalid/members")
      assert html_response(conn, 404)
    end

    test "list_members returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/admin/games/#{non_existent_id}/members")
      assert html_response(conn, 404)
    end

    test "add_member returns 404 for invalid game id format", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/games/invalid/members", %{"user_id" => "123", "role" => "member"})

      assert html_response(conn, 404)
    end

    test "add_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/admin/games/#{non_existent_id}/members", %{
          "user_id" => "123",
          "role" => "member"
        })

      assert html_response(conn, 404)
    end

    test "remove_member returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/admin/games/invalid/members/123")
      assert html_response(conn, 404)
    end

    test "remove_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/admin/games/#{non_existent_id}/members/123")
      assert html_response(conn, 404)
    end
  end

  defp create_game(%{scope: scope}) do
    game = game_fixture(scope)

    %{game: game}
  end
end
