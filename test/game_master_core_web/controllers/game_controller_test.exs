defmodule GameMasterCoreWeb.GameControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures
  alias GameMasterCore.Games.Game

  @create_attrs %{
    name: "some name",
    content: "some content",
    setting: "some setting"
  }
  @update_attrs %{
    name: "some updated name",
    content: "some updated content",
    setting: "some updated setting"
  }
  @invalid_attrs %{name: nil, content: nil, setting: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user} do
    conn = authenticate_api_user(conn, user)
    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all games", %{conn: conn} do
      conn = get(conn, ~p"/api/games")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create game" do
    test "renders game when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/games", game: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name",
               "setting" => "some setting"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/games", game: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update game" do
    setup [:create_game]

    test "renders game when data is valid", %{conn: conn, game: %Game{id: id} = game} do
      conn = put(conn, ~p"/api/games/#{game}", game: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name",
               "setting" => "some updated setting"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = put(conn, ~p"/api/games/#{game}", game: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete game" do
    setup [:create_game]

    test "deletes chosen game", %{conn: conn, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game}")
      assert json_response(conn, 404)
    end
  end

  describe "error handling" do
    test "show returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid")
      response = json_response(conn, 404)

      # Check the exact response format matches Swagger expectations
      assert %{"errors" => %{"detail" => "Not Found"}} = response
    end

    test "show returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "update returns 404 for invalid game id format", %{conn: conn} do
      conn = put(conn, ~p"/api/games/invalid", game: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "update returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/api/games/#{non_existent_id}", game: %{name: "test"})
      assert json_response(conn, 404)
    end

    test "delete returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/api/games/invalid")
      assert json_response(conn, 404)
    end

    test "delete returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{non_existent_id}")
      assert json_response(conn, 404)
    end

    test "add_member returns 404 for invalid game id format", %{conn: conn} do
      conn = post(conn, ~p"/api/games/invalid/members", %{"user_id" => "123", "role" => "member"})
      assert json_response(conn, 404)
    end

    test "add_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{non_existent_id}/members", %{
          "user_id" => "123",
          "role" => "member"
        })

      assert json_response(conn, 404)
    end

    test "remove_member returns 404 for invalid game id format", %{conn: conn} do
      conn = delete(conn, ~p"/api/games/invalid/members/123")
      assert json_response(conn, 404)
    end

    test "remove_member returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{non_existent_id}/members/123")
      assert json_response(conn, 404)
    end

    test "list_members returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid/members")
      assert json_response(conn, 404)
    end

    test "list_members returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}/members")
      assert json_response(conn, 404)
    end

    test "list_entities returns 404 for invalid game id format", %{conn: conn} do
      conn = get(conn, ~p"/api/games/invalid/links")
      assert json_response(conn, 404)
    end

    test "list_entities returns 404 for non-existent game", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{non_existent_id}/links")
      assert json_response(conn, 404)
    end
  end

  defp create_game(%{scope: scope}) do
    game = game_fixture(scope)

    %{game: game}
  end
end
