defmodule GameMasterCoreWeb.FactionControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.FactionsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures
  alias GameMasterCore.Factions.Faction

  @create_attrs %{
    name: "some name",
    description: "some description"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user_with_game

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
    test "lists all factions", %{conn: conn, scope: scope} do
      conn = get(conn, ~p"/api/games/#{scope.game}/factions")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create faction" do
    test "renders faction when data is valid", %{conn: conn, scope: scope} do
      conn = post(conn, ~p"/api/games/#{scope.game}/factions", faction: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{scope.game}/factions/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, scope: scope} do
      conn = post(conn, ~p"/api/games/#{scope.game}/factions", faction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update faction" do
    setup [:create_faction]

    test "renders faction when data is valid", %{
      conn: conn,
      faction: %Faction{id: id} = faction,
      scope: scope
    } do
      conn = put(conn, ~p"/api/games/#{scope.game}/factions/#{faction}", faction: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{scope.game}/factions/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, faction: faction, scope: scope} do
      conn = put(conn, ~p"/api/games/#{scope.game}/factions/#{faction}", faction: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete faction" do
    setup [:create_faction]

    test "deletes chosen faction", %{conn: conn, faction: faction, scope: scope} do
      conn = delete(conn, ~p"/api/games/#{scope.game}/factions/#{faction}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{scope.game}/factions/#{faction}")
      end
    end
  end

  defp create_faction(%{scope: scope}) do
    faction = faction_fixture(scope)

    %{faction: faction}
  end
end
