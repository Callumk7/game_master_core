defmodule GameMasterCoreWeb.Admin.NoteController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games
  alias GameMasterCore.Notes
  alias GameMasterCore.Notes.Note

  plug :load_game

  def index(conn, _params) do
    notes = Notes.list_notes_for_game(conn.assigns.current_scope)
    render(conn, :index, notes: notes)
  end

  def new(conn, _params) do
    changeset =
      Notes.change_note(conn.assigns.current_scope, %Note{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"note" => note_params}) do
    case Notes.create_note_for_game(conn.assigns.current_scope, note_params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "Note created successfully.")
        |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/notes/#{note}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, note: note)
  end

  def edit(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)
    changeset = Notes.change_note(conn.assigns.current_scope, note)
    render(conn, :edit, note: note, changeset: changeset)
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)

    case Notes.update_note(conn.assigns.current_scope, note, note_params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "Note updated successfully.")
        |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/notes/#{note}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, note: note, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)
    {:ok, _note} = Notes.delete_note(conn.assigns.current_scope, note)

    conn
    |> put_flash(:info, "Note deleted successfully.")
    |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/notes")
  end

  defp load_game(conn, _opts) do
    current_scope = conn.assigns.current_scope

    if game_id = conn.params["game_id"] do
      game = Games.get_game!(current_scope, game_id)

      conn
      |> assign(:game, game)
      |> assign(:current_scope, Scope.put_game(current_scope, game))
    else
      conn
    end
  end
end
