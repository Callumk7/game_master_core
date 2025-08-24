defmodule GameMasterCoreWeb.NoteController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Notes
  alias GameMasterCore.Notes.Note

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    notes = Notes.list_notes_for_game(conn.assigns.current_scope)
    render(conn, :index, notes: notes)
  end

  def create(conn, %{"note" => note_params}) do
    with {:ok, %Note{} = note} <-
           Notes.create_note_for_game(conn.assigns.current_scope, note_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{note.game_id}/notes/#{note}")
      |> render(:show, note: note)
    end
  end

  def show(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, note: note)
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Note{} = note} <- Notes.update_note(conn.assigns.current_scope, note, note_params) do
      render(conn, :show, note: note)
    end
  end

  def delete(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Note{}} <- Notes.delete_note(conn.assigns.current_scope, note) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_link(conn, %{"note_id" => note_id} = params) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, note_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_note_link(conn.assigns.current_scope, note.id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        note_id: note.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  def list_links(conn, %{"note_id" => note_id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, note_id)

    links = Notes.linked_characters(conn.assigns.current_scope, note.id)

    render(conn, :links, note: note, characters: links)
  end

  def delete_link(conn, %{
        "note_id" => note_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, note_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_note_link(conn.assigns.current_scope, note.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_note_link(scope, note_id, :character, character_id) do
    Notes.link_character(scope, note_id, character_id)
  end

  defp create_note_link(_scope, _note_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :note, entity_type}}
  end

  defp delete_note_link(scope, note_id, :character, character_id) do
    Notes.unlink_character(scope, note_id, character_id)
  end

  defp delete_note_link(_scope, _note_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :note, entity_type}}
  end
end
