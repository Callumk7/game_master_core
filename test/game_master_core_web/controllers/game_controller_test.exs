defmodule GameMasterCoreWeb.GameControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.GamesFixtures
  alias GameMasterCore.Games.Game

  @create_attrs %{
    name: "some name",
    description: "some description",
    setting: "some setting"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    setting: "some updated setting"
  }
  @invalid_attrs %{name: nil, description: nil, setting: nil}

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
               "description" => "some description",
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
               "description" => "some updated description",
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

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}")
      end
    end
  end

  defp create_game(%{scope: scope}) do
    game = game_fixture(scope)

    %{game: game}
  end
end
