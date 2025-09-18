defmodule GameMasterCoreWeb.Swagger.NoteSwagger do
  @moduledoc """
  Swagger documentation definitions for NoteController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/notes")
        summary("List notes")
        description("Retrieve all notes for a specific game")
        operation_id("listNotes")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:NotesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
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
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:NoteCreateRequest), "Note parameters", required: true)
        end

        response(201, "Created", Schema.ref(:NoteResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/notes/{id}")
        summary("Get a note")
        description("Retrieve a specific note by its ID")
        operation_id("getNote")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Note ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:NoteResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
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
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Note ID", required: true, format: :uuid)
          body(:body, Schema.ref(:NoteUpdateRequest), "Note parameters", required: true)
        end

        response(200, "Success", Schema.ref(:NoteResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/notes/{id}")
        summary("Delete a note")
        description("Delete a specific note by its ID")
        operation_id("deleteNote")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Note ID", required: true, format: :uuid)
        end

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create_link do
        post("/api/games/{game_id}/notes/{note_id}/links")
        summary("Create a link")

        description(
          "Create a link between a note and another entity (character, faction, location, quest)"
        )

        operation_id("createNoteLink")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          note_id(:path, :string, "Note ID", required: true, format: :uuid)

          entity_type(:query, :string, "Entity type to link",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:query, :string, "Entity ID to link", required: true, format: :uuid)
        end

        response(201, "Created", %{
          "type" => "object",
          "properties" => %{
            "message" => %{"type" => "string"},
            "note_id" => %{"type" => "string", "format" => "uuid"},
            "entity_type" => %{"type" => "string"},
            "entity_id" => %{"type" => "string", "format" => "uuid"}
          }
        })

        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :list_links do
        get("/api/games/{game_id}/notes/{note_id}/links")
        summary("List note links")
        description("Retrieve all entities linked to a specific note")
        operation_id("getNoteLinks")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          note_id(:path, :string, "Note ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:NoteLinksResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
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
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          note_id(:path, :string, "Note ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
        end

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end
    end
  end
end
