defmodule GameMasterCoreWeb.Admin.NoteControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.NotesFixtures
  import GameMasterCore.GamesFixtures

  @create_attrs %{name: "some name", content: "some content"}
  @update_attrs %{name: "some updated name", content: "some updated content"}
  @invalid_attrs %{name: nil, content: nil}

  setup :register_and_log_in_user

  setup %{scope: scope} do
    game = game_fixture(scope)
    %{game: game}
  end

  describe "index" do
    test "lists all notes", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/notes")
      assert html_response(conn, 200) =~ "Listing Notes"
    end
  end

  describe "new note" do
    test "renders form", %{conn: conn, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/notes/new")
      assert html_response(conn, 200) =~ "New Note"
    end
  end

  describe "create note" do
    test "redirects to show when data is valid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/notes", note: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/notes/#{id}"

      conn = get(conn, ~p"/admin/games/#{game}/notes/#{id}")
      assert html_response(conn, 200) =~ "Note #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn, game: game} do
      conn = post(conn, ~p"/admin/games/#{game}/notes", note: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Note"
    end
  end

  describe "edit note" do
    setup [:create_note]

    test "renders form for editing chosen note", %{conn: conn, note: note, game: game} do
      conn = get(conn, ~p"/admin/games/#{game}/notes/#{note}/edit")
      assert html_response(conn, 200) =~ "Edit Note"
    end
  end

  describe "update note" do
    setup [:create_note]

    test "redirects when data is valid", %{conn: conn, note: note, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}/notes/#{note}", note: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/games/#{game}/notes/#{note}"

      conn = get(conn, ~p"/admin/games/#{game}/notes/#{note}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, note: note, game: game} do
      conn = put(conn, ~p"/admin/games/#{game}/notes/#{note}", note: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Note"
    end
  end

  describe "delete note" do
    setup [:create_note]

    test "deletes chosen note", %{conn: conn, note: note, game: game} do
      conn = delete(conn, ~p"/admin/games/#{game}/notes/#{note}")
      assert redirected_to(conn) == ~p"/admin/games/#{game}/notes"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/games/#{game}/notes/#{note}")
      end
    end
  end

  defp create_note(%{scope: scope, game: game}) do
    note = note_fixture(scope, %{game_id: game.id})

    %{note: note}
  end
end
