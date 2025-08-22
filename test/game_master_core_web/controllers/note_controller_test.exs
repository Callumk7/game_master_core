defmodule GameMasterCoreWeb.NoteControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.NotesFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures
  alias GameMasterCore.Notes.Note

  @create_attrs %{
    name: "some name",
    content: "some content"
  }
  @update_attrs %{
    name: "some updated name",
    content: "some updated content"
  }
  @invalid_attrs %{name: nil, content: nil}

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
    test "lists notes for a game that user owns", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "denies access to notes for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{other_game.id}/notes")
      end
    end
  end

  describe "create note" do
    test "renders note when data is valid for owned game", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game.id}/notes", note: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some content",
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "denies note creation for games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/games/#{other_game.id}/notes", note: @create_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/api/games/#{game.id}/notes", note: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update note" do
    setup [:create_note]

    test "renders note when data is valid", %{conn: conn, game: game, note: %Note{id: id} = note} do
      conn = put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}", note: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game.id}/notes/#{id}")

      assert %{
               "id" => ^id,
               "content" => "some updated content",
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "denies update for notes in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        put(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}", note: @update_attrs)
      end
    end

    test "renders errors when data is invalid", %{conn: conn, game: game, note: note} do
      conn = put(conn, ~p"/api/games/#{game.id}/notes/#{note.id}", note: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete note" do
    setup [:create_note]

    test "deletes chosen note", %{conn: conn, game: game, note: note} do
      conn = delete(conn, ~p"/api/games/#{game.id}/notes/#{note.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/games/#{game.id}/notes/#{note.id}")
      end
    end

    test "denies deletion for notes in games user cannot access", %{conn: conn, scope: _scope} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      other_note = note_fixture(other_user_scope, %{game_id: other_game.id})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/games/#{other_game.id}/notes/#{other_note.id}")
      end
    end
  end

  describe "game member access" do
    test "allows game members to access notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_token = GameMasterCore.Accounts.create_user_api_token(member_scope.user)

      member_conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{member_token}")

      conn = get(member_conn, ~p"/api/games/#{game.id}/notes")
      assert json_response(conn, 200)["data"] == []
    end

    test "allows game members to create notes", %{conn: _conn, game: game, scope: scope} do
      member_scope = user_scope_fixture()
      {:ok, _} = GameMasterCore.Games.add_member(scope, game, member_scope.user.id)

      # Login as member
      member_token = GameMasterCore.Accounts.create_user_api_token(member_scope.user)

      member_conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{member_token}")

      conn = post(member_conn, ~p"/api/games/#{game.id}/notes", note: @create_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  defp create_note(%{scope: scope, game: game}) do
    note = note_fixture(scope, %{game_id: game.id})

    %{note: note}
  end
end
