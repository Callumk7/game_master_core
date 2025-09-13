defmodule GameMasterCoreWeb.Admin.CharacterControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.CharactersFixtures
  import GameMasterCore.GamesFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    class: "some class",
    level: 42,
    image_url: "some image_url"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    class: "some updated class",
    level: 43,
    image_url: "some updated image_url"
  }
  @invalid_attrs %{name: nil, description: nil, class: nil, level: nil, image_url: nil}

  setup :register_and_log_in_user

  setup %{scope: scope} do
    game = game_fixture(scope)
    %{game: game}
  end

  describe "index" do
    test "lists all characters", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/characters")
      assert html_response(conn, 200) =~ "Listing Characters"
    end
  end

  describe "new character" do
    test "renders form", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/characters/new")
      assert html_response(conn, 200) =~ "New Character"
    end
  end

  describe "create character" do
    test "redirects to show when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/characters", character: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/characters/#{id}"

      conn = get(conn, ~p"/admin/games/#{game}/characters/#{id}")
      assert html_response(conn, 200) =~ "Character #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/characters", character: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Character"
    end
  end

  describe "edit character" do
    setup [:create_character]

    test "renders form for editing chosen character", %{
      conn: conn,
      character: character,
      game: game
    } do
      conn = get(conn, ~p"/admin/games/#{game}/characters/#{character}/edit")
      assert html_response(conn, 200) =~ "Edit Character"
    end
  end

  describe "update character" do
    setup [:create_character]

    test "redirects when data is valid", %{conn: conn, character: character, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}/characters/#{character}", character: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/characters/#{character}"

      conn = get(conn, ~p"/admin/games/#{game}/characters/#{character}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, character: character, game: game} do
      conn =
        put(conn, ~p"/admin/games/#{game}/characters/#{character}", character: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Character"
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character, game: game} do
      conn = delete(conn, ~p"/admin/games/#{game}/characters/#{character}")
      assert redirected_to(conn) == ~p"/admin/games/#{game}/characters"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/games/#{game}/characters/#{character}")
      end
    end
  end

  defp create_character(%{scope: scope, game: game}) do
    character = character_fixture(scope, %{game_id: game.id})

    %{character: character}
  end
end
