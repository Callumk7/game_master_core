defmodule GameMasterCoreWeb.NoteController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Notes
  alias GameMasterCore.Notes.Note
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :index do
    get("/api/games/{game_id}/notes")
    summary("List notes")
    description("Retrieve all notes for a specific game")
    operation_id("listNotes")
    tag("GameMaster")
    produces("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
    end

    response(200, "Success", Schema.ref(:NotesResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def index(conn, _params) do
    notes = Notes.list_notes_for_game(conn.assigns.current_scope)
    render(conn, :index, notes: notes)
  end

  swagger_path :create do
    post("/api/games/{game_id}/notes")
    summary("Create a note")
    description("Create a new note for the specified game")
    operation_id("createNote")
    tag("GameMaster")
    consumes("application/json")
    produces("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      body(:body, Schema.ref(:NoteRequest), "Note parameters", required: true)
    end

    response(201, "Created", Schema.ref(:NoteResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
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

  swagger_path :show do
    get("/api/games/{game_id}/notes/{id}")
    summary("Get a note")
    description("Retrieve a specific note by its ID")
    operation_id("getNote")
    tag("GameMaster")
    produces("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Note ID", required: true)
    end

    response(200, "Success", Schema.ref(:NoteResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, note: note)
  end

  swagger_path :update do
    put("/api/games/{game_id}/notes/{id}")
    summary("Update a note")
    description("Update a specific note with the provided parameters")
    operation_id("updateNote")
    tag("GameMaster")
    consumes("application/json")
    produces("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Note ID", required: true)
      body(:body, Schema.ref(:NoteRequest), "Note parameters", required: true)
    end

    response(200, "Success", Schema.ref(:NoteResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Note{} = note} <- Notes.update_note(conn.assigns.current_scope, note, note_params) do
      render(conn, :show, note: note)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/notes/{id}")
    summary("Delete a note")
    description("Delete a specific note by its ID")
    operation_id("deleteNote")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Note ID", required: true)
    end

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Note{}} <- Notes.delete_note(conn.assigns.current_scope, note) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :create_link do
    post("/api/games/{game_id}/notes/{note_id}/links")
    summary("Create a link")

    description(
      "Create a link between a note and another entity (character, faction, location, quest)"
    )

    operation_id("createNoteLink")
    tag("GameMaster")
    consumes("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      note_id(:path, :integer, "Note ID", required: true)

      entity_type(:query, :string, "Entity type to link",
        required: true,
        enum: ["character", "faction", "location", "quest", "note"]
      )

      entity_id(:query, :integer, "Entity ID to link", required: true)
    end

    response(201, "Created", %{
      "type" => "object",
      "properties" => %{
        "message" => %{"type" => "string"},
        "note_id" => %{"type" => "integer"},
        "entity_type" => %{"type" => "string"},
        "entity_id" => %{"type" => "integer"}
      }
    })

    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
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

  swagger_path :list_links do
    get("/api/games/{game_id}/notes/{note_id}/links")
    summary("List note links")
    description("Retrieve all entities linked to a specific note")
    operation_id("getNoteLinks")
    tag("GameMaster")
    produces("application/json")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      note_id(:path, :integer, "Note ID", required: true)
    end

    response(200, "Success", Schema.ref(:NoteLinksResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_links(conn, %{"note_id" => note_id}) do
    note = Notes.get_note_for_game!(conn.assigns.current_scope, note_id)

    links = Notes.links(conn.assigns.current_scope, note.id)

    render(conn, :links,
      note: note,
      characters: links.characters,
      factions: links.factions,
      locations: links.locations,
      quests: links.quests,
      notes: links.notes
    )
  end

  swagger_path :delete_link do
    PhoenixSwagger.Path.delete(
      "/api/games/{game_id}/notes/{note_id}/links/{entity_type}/{entity_id}"
    )

    summary("Delete a link")
    description("Remove a link between a note and another entity")
    operation_id("deleteNoteLink")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      note_id(:path, :integer, "Note ID", required: true)

      entity_type(:path, :string, "Entity type",
        required: true,
        enum: ["character", "faction", "location", "quest", "note"]
      )

      entity_id(:path, :integer, "Entity ID", required: true)
    end

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
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

  defp create_note_link(scope, note_id, :faction, faction_id) do
    Notes.link_faction(scope, note_id, faction_id)
  end

  defp create_note_link(scope, note_id, :location, location_id) do
    Notes.link_location(scope, note_id, location_id)
  end

  defp create_note_link(scope, note_id, :quest, quest_id) do
    Notes.link_quest(scope, note_id, quest_id)
  end

  defp create_note_link(scope, note_id, :note, other_note_id) do
    Notes.link_note(scope, note_id, other_note_id)
  end

  defp create_note_link(_scope, _note_id, entity_type, _entity_id) do
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
end
