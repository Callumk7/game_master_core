defmodule GameMasterCoreWeb.Admin.FactionControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.FactionsFixtures
  import GameMasterCore.GamesFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  setup %{scope: scope} do
    game = game_fixture(scope)
    %{game: game}
  end

  describe "index" do
    test "lists all factions", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/factions")
      assert html_response(conn, 200) =~ "Listing Factions"
    end
  end

  describe "new faction" do
    test "renders form", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/factions/new")
      assert html_response(conn, 200) =~ "New Faction"
    end
  end

  describe "create faction" do
    test "redirects to show when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/factions", faction: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/factions/#{id}"

      conn = get(conn, ~p"/admin/games/#{game}/factions/#{id}")
      assert html_response(conn, 200) =~ "Faction #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/factions", faction: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Faction"
    end
  end

  describe "edit faction" do
    setup [:create_faction]

    test "renders form for editing chosen faction", %{conn: conn, faction: faction, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/factions/#{faction}/edit")
      assert html_response(conn, 200) =~ "Edit Faction"
    end
  end

  describe "update faction" do
    setup [:create_faction]

    test "redirects when data is valid", %{conn: conn, faction: faction, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}/factions/#{faction}", faction: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/factions/#{faction}"

      conn = get(conn, ~p"/admin/games/#{game}/factions/#{faction}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, faction: faction, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}/factions/#{faction}", faction: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Faction"
    end
  end

  describe "delete faction" do
    setup [:create_faction]

    test "deletes chosen faction", %{conn: conn, faction: faction, game: game} do
      conn = delete(conn, ~p"/admin/games/#{game}/factions/#{faction}")
      assert redirected_to(conn) == ~p"/admin/games/#{game}/factions"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/games/#{game}/factions/#{faction}")
      end
    end
  end

  defp create_faction(%{scope: scope, game: game}) do
    faction = faction_fixture(scope, %{game_id: game.id})

    %{faction: faction}
  end
end
