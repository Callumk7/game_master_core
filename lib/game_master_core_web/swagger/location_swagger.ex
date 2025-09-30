defmodule GameMasterCoreWeb.Swagger.LocationSwagger do
  @moduledoc """
  Swagger documentation definitions for LocationController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/locations")
        summary("List locations")
        description("Get all locations in a game")
        operation_id("listLocations")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:LocationsResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :tree do
        get("/api/games/{game_id}/locations/tree")
        summary("Get location tree")
        description("Get hierarchical tree structure of all locations in a game")
        operation_id("getLocationTree")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:LocationTreeResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/locations")
        summary("Create location")
        description("Create a new location in the game")
        operation_id("createLocation")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:LocationCreateRequest), "Location to create", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created", Schema.ref(:LocationResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/locations/{id}")
        summary("Get location")
        description("Get a specific location by ID")
        operation_id("getLocation")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Location ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:LocationResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/locations/{id}")
        summary("Update location")
        description("Update an existing location")
        operation_id("updateLocation")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Location ID", required: true, format: :uuid)
          body(:body, Schema.ref(:LocationUpdateRequest), "Location updates", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:LocationResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/locations/{id}")
        summary("Delete location")
        description("Delete a location from the game")
        operation_id("deleteLocation")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Location ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create_link do
        post("/api/games/{game_id}/locations/{location_id}/links")
        summary("Create location link")
        description("Link a location to another entity (note, faction, etc.)")
        operation_id("createLocationLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          location_id(:path, :string, "Location ID", required: true, format: :uuid)

          body(:body, Schema.ref(:LinkRequest), "Link creation data", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created")
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :list_links do
        get("/api/games/{game_id}/locations/{location_id}/links")
        summary("Get location links")
        description("Get all entities linked to a location")
        operation_id("getLocationLinks")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          location_id(:path, :string, "Location ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:LocationLinksResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :delete_link do
        PhoenixSwagger.Path.delete(
          "/api/games/{game_id}/locations/{location_id}/links/{entity_type}/{entity_id}"
        )

        summary("Delete location link")
        operation_id("deleteLocationLink")
        tag("GameMaster")
        description("Remove a link between a location and another entity")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          location_id(:path, :string, "Location ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update_link do
        put("/api/games/{game_id}/locations/{location_id}/links/{entity_type}/{entity_id}")
        summary("Update a location link")
        description("Update link metadata between a location and another entity")
        operation_id("updateLocationLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          location_id(:path, :string, "Location ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["note", "character", "faction", "quest", "location"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          body(:body, Schema.ref(:LinkUpdateRequest), "Link update data", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", %{
          "type" => "object",
          "properties" => %{
            "message" => %{"type" => "string"},
            "location_id" => %{"type" => "string", "format" => "uuid"},
            "entity_type" => %{"type" => "string"},
            "entity_id" => %{"type" => "string", "format" => "uuid"},
            "updated_at" => %{"type" => "string", "format" => "date-time"}
          }
        })

        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end
    end
  end
end
