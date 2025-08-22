defmodule GameMasterCoreWeb.NoteController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Notes
  alias GameMasterCore.Notes.Note
  alias GameMasterCore.Games

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    notes = Notes.list_notes_for_game(conn.assigns.current_scope, game)
    render(conn, :index, notes: notes)
  end

  def create(conn, %{"game_id" => game_id, "note" => note_params}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)

    with {:ok, %Note{} = note} <-
           Notes.create_note_for_game(conn.assigns.current_scope, game, note_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{game}/notes/#{note}")
      |> render(:show, note: note)
    end
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    note = Notes.get_note_for_game!(conn.assigns.current_scope, game, id)
    render(conn, :show, note: note)
  end

  def update(conn, %{"game_id" => game_id, "id" => id, "note" => note_params}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    note = Notes.get_note_for_game!(conn.assigns.current_scope, game, id)

    with {:ok, %Note{} = note} <- Notes.update_note(conn.assigns.current_scope, note, note_params) do
      render(conn, :show, note: note)
    end
  end

  def delete(conn, %{"game_id" => game_id, "id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    note = Notes.get_note_for_game!(conn.assigns.current_scope, game, id)

    with {:ok, %Note{}} <- Notes.delete_note(conn.assigns.current_scope, note) do
      send_resp(conn, :no_content, "")
    end
  end
end
