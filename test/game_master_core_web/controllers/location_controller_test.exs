defmodule GameMasterCoreWeb.LocationControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.LocationsFixtures
  import GameMasterCore.GamesFixtures

  alias GameMasterCore.Locations.Location

  @create_attrs %{
    name: "some name",
    type: "city",
    description: "some description"
  }
  @update_attrs %{
    name: "some updated name",
    type: "settlement",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, type: nil, description: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    user_token = GameMasterCore.Accounts.create_user_api_token(user)
    game = game_fixture(scope)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{user_token}")

    {:ok, conn: conn, game: game}
  end

  describe "index" do
    test "lists all locations", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game}/locations")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create location" do
    test "renders location when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/locations", location: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/locations/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "name" => "some name",
               "type" => "city"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/locations", location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update location" do
    setup [:create_location]

    test "renders location when data is valid", %{
      conn: conn,
      location: %Location{id: id} = location,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game}/locations/#{location}", location: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/locations/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "name" => "some updated name",
               "type" => "settlement"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, location: location, game: game} do
      conn = put(conn, ~p"/api/games/#{game}/locations/#{location}", location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete location" do
    setup [:create_location]

    test "deletes chosen location", %{conn: conn, location: location, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/locations/#{location}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/locations/#{location}")
      end
    end
  end

  defp create_location(%{scope: scope, game: game}) do
    location = location_fixture(scope, %{game_id: game.id})

    %{location: location}
  end
end
