defmodule GameMasterCoreWeb.NoteController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Notes
  alias GameMasterCore.Notes.Note
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.NoteSwagger

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
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, note: note)
    end
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, id),
         {:ok, %Note{} = note} <- Notes.update_note(conn.assigns.current_scope, note, note_params) do
      render(conn, :show, note: note)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, id),
         {:ok, %Note{}} <- Notes.delete_note(conn.assigns.current_scope, note) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_link(conn, %{"note_id" => note_id} = params) do
    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    # Extract metadata fields
    metadata_attrs = %{
      relationship_type: Map.get(params, "relationship_type"),
      description: Map.get(params, "description"),
      strength: Map.get(params, "strength"),
      is_active: Map.get(params, "is_active"),
      metadata: Map.get(params, "metadata")
    }

    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_note_link(
             conn.assigns.current_scope,
             note.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
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
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id) do
      links = Notes.links(conn.assigns.current_scope, note_id)

      render(conn, :links,
        note: note,
        characters: links.characters,
        factions: links.factions,
        locations: links.locations,
        quests: links.quests,
        notes: links.notes
      )
    end
  end

  def delete_link(conn, %{
        "note_id" => note_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_note_link(conn.assigns.current_scope, note.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def update_link(
        conn,
        %{
          "note_id" => note_id,
          "entity_type" => entity_type,
          "entity_id" => entity_id
        } = params
      ) do
    # Extract metadata fields
    metadata_attrs = %{
      relationship_type: Map.get(params, "relationship_type"),
      description: Map.get(params, "description"),
      strength: Map.get(params, "strength"),
      is_active: Map.get(params, "is_active"),
      metadata: Map.get(params, "metadata")
    }

    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_note_link(
             conn.assigns.current_scope,
             note.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        note_id: note.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
    end
  end

  # Private helpers for link management

  defp create_note_link(scope, note_id, :character, character_id, metadata_attrs) do
    Notes.link_character(scope, note_id, character_id, metadata_attrs)
  end

  defp create_note_link(scope, note_id, :faction, faction_id, metadata_attrs) do
    Notes.link_faction(scope, note_id, faction_id, metadata_attrs)
  end

  defp create_note_link(scope, note_id, :location, location_id, metadata_attrs) do
    Notes.link_location(scope, note_id, location_id, metadata_attrs)
  end

  defp create_note_link(scope, note_id, :quest, quest_id, metadata_attrs) do
    Notes.link_quest(scope, note_id, quest_id, metadata_attrs)
  end

  defp create_note_link(scope, note_id, :note, other_note_id, metadata_attrs) do
    Notes.link_note(scope, note_id, other_note_id, metadata_attrs)
  end

  defp create_note_link(_scope, _note_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :note, entity_type}}
  end

  defp delete_note_link(scope, note_id, :character, character_id) do
    Notes.unlink_character(scope, note_id, character_id)
  end

  defp delete_note_link(scope, note_id, :faction, faction_id) do
    Notes.unlink_faction(scope, note_id, faction_id)
  end

  defp delete_note_link(scope, note_id, :location, location_id) do
    Notes.unlink_location(scope, note_id, location_id)
  end

  defp delete_note_link(scope, note_id, :quest, quest_id) do
    Notes.unlink_quest(scope, note_id, quest_id)
  end

  defp delete_note_link(scope, note_id, :note, other_note_id) do
    Notes.unlink_note(scope, note_id, other_note_id)
  end

  defp delete_note_link(_scope, _note_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :note, entity_type}}
  end

  defp update_note_link(scope, note_id, :character, character_id, metadata_attrs) do
    Notes.update_link_character(scope, note_id, character_id, metadata_attrs)
  end

  defp update_note_link(scope, note_id, :faction, faction_id, metadata_attrs) do
    Notes.update_link_faction(scope, note_id, faction_id, metadata_attrs)
  end

  defp update_note_link(scope, note_id, :location, location_id, metadata_attrs) do
    Notes.update_link_location(scope, note_id, location_id, metadata_attrs)
  end

  defp update_note_link(scope, note_id, :quest, quest_id, metadata_attrs) do
    Notes.update_link_quest(scope, note_id, quest_id, metadata_attrs)
  end

  defp update_note_link(scope, note_id, :note, other_note_id, metadata_attrs) do
    Notes.update_link_note(scope, note_id, other_note_id, metadata_attrs)
  end

  defp update_note_link(_scope, _note_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :note, entity_type}}
  end

  # Pinning endpoints

  def pin(conn, %{"note_id" => note_id}) do
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id),
         {:ok, updated_note} <- Notes.pin_note(conn.assigns.current_scope, note) do
      render(conn, :show, note: updated_note)
    end
  end

  def unpin(conn, %{"note_id" => note_id}) do
    with {:ok, note} <- Notes.fetch_note_for_game(conn.assigns.current_scope, note_id),
         {:ok, updated_note} <- Notes.unpin_note(conn.assigns.current_scope, note) do
      render(conn, :show, note: updated_note)
    end
  end
end
