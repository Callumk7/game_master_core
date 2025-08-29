defmodule GameMasterCoreWeb.QuestControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.QuestsFixtures
  alias GameMasterCore.Quests.Quest

  @create_attrs %{
    name: "some name",
    content: "some content"
  }
  @update_attrs %{
    name: "some updated name",
    content: "some updated content"
  }
  @invalid_attrs %{name: nil, content: nil}

  setup :register_and_log_in_user_with_game

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all quests", %{conn: conn, scope: scope} do
      conn = get(conn, ~p"/api/games/#{scope.game}/quests")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create quest" do
    test "renders quest when data is valid", %{conn: conn, scope: scope} do
      conn = post(conn, ~p"/api/games/#{scope.game}/quests", quest: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{scope.game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, scope: scope} do
      conn = post(conn, ~p"/api/games/#{scope.game}/quests", quest: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update quest" do
    setup [:create_quest]

    test "renders quest when data is valid", %{conn: conn, quest: %Quest{id: id} = quest, scope: scope} do
      conn = put(conn, ~p"/api/games/#{scope.game}/quests/#{quest}", quest: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{scope.game}/quests/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, quest: quest, scope: scope} do
      conn = put(conn, ~p"/api/games/#{scope.game}/quests/#{quest}", quest: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete quest" do
    setup [:create_quest]

    test "deletes chosen quest", %{conn: conn, quest: quest, scope: scope} do
      conn = delete(conn, ~p"/api/games/#{scope.game}/quests/#{quest}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{scope.game}/quests/#{quest}")
      end
    end
  end

  defp create_quest(%{scope: scope}) do
    quest = quest_fixture(scope)

    %{quest: quest}
  end
end
