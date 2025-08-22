defmodule GameMasterCoreWeb.CharacterControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.CharactersFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  alias GameMasterCore.Characters.Character

  @create_attrs %{
    name: "some name",
    level: 42,
    description: "some description",
    class: "some class",
    image_url: "some image_url"
  }
  @update_attrs %{
    name: "some updated name",
    level: 43,
    description: "some updated description",
    class: "some updated class",
    image_url: "some updated image_url"
  }
  @invalid_attrs %{name: nil, level: nil, description: nil, class: nil, image_url: nil}

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
    test "lists all characters", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/characters")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to characters for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/characters")
      end
    end
  end

  describe "create character" do
    test "renders character when data is valid for owned game", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/characters/#{id}")

      assert %{
               "id" => ^id,
               "class" => "some class",
               "description" => "some description",
               "image_url" => "some image_url",
               "level" => 42,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies character creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/characters", character: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game}/characters", character: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update character" do
    setup [:create_character]

    test "renders character when data is valid", %{
      conn: conn,
      character: %Character{id: id} = character,
      game: game
    } do
      conn = put(conn, ~p"/api/games/#{game.id}/characters/#{id}", character: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{id}")

      assert %{
               "id" => ^id,
               "class" => "some updated class",
               "description" => "some updated description",
               "image_url" => "some updated image_url",
               "level" => 43,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, character: character, game: game} do
      conn =
        put(conn, ~p"/api/games/#{game.id}/characters/#{character}", character: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character, game: game} do
      conn = delete(conn, ~p"/api/games/#{game}/characters/#{character}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game}/characters/#{character}")
      end
    end

    test "denies deletion for characters in games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_character = character_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/characters/#{other_character.id}")
      end
    end
  end

  defp create_character(%{scope: scope, game: game}) do
    character = character_fixture(scope, %{game_id: game.id})

    %{character: character}
  end
end
