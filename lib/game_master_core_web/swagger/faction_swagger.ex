defmodule GameMasterCoreWeb.Swagger.FactionSwagger do
  @moduledoc """
  Swagger documentation definitions for FactionController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/factions")
        summary("List factions")
        description("Get all factions in a game")
        operation_id("listFactions")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:FactionsResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/factions")
        summary("Create faction")
        description("Create a new faction in the game with optional entity links")
        operation_id("createFaction")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:FactionCreateRequest), "Faction to create", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created", Schema.ref(:FactionResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:ValidationError))
      end

      swagger_path :show do
        get("/api/games/{game_id}/factions/{id}")
        summary("Get faction")
        description("Get a specific faction by ID")
        operation_id("getFaction")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Faction ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:FactionResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/factions/{id}")
        summary("Update faction")
        description("Update an existing faction")
        operation_id("updateFaction")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Faction ID", required: true, format: :uuid)
          body(:body, Schema.ref(:FactionUpdateRequest), "Faction updates", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:FactionResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:ValidationError))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/factions/{id}")
        summary("Delete faction")
        description("Delete a faction from the game")
        operation_id("deleteFaction")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Faction ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create_link do
        post("/api/games/{game_id}/factions/{faction_id}/links")
        summary("Create faction link")
        description("Link a faction to another entity (note, character, etc.)")
        operation_id("createFactionLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          faction_id(:path, :string, "Faction ID", required: true, format: :uuid)

          body(:body, Schema.ref(:LinkRequest), "Link creation data", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created")
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:ValidationError))
      end

      swagger_path :list_links do
        get("/api/games/{game_id}/factions/{faction_id}/links")
        summary("Get faction links")
        description("Get all entities linked to a faction")
        operation_id("getFactionLinks")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          faction_id(:path, :string, "Faction ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:FactionLinksResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :members do
        get("/api/games/{game_id}/factions/{faction_id}/members")
        summary("Get faction members")

        description("Get all characters that have this faction as their primary faction")

        operation_id("getFactionMembers")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          faction_id(:path, :string, "Faction ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:FactionMembersResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :delete_link do
        PhoenixSwagger.Path.delete(
          "/api/games/{game_id}/factions/{faction_id}/links/{entity_type}/{entity_id}"
        )

        summary("Delete faction link")
        description("Remove a link between a faction and another entity")
        operation_id("deleteFactionLink")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          faction_id(:path, :string, "Faction ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "location", "quest", "note", "faction"]
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
        put("/api/games/{game_id}/factions/{faction_id}/links/{entity_type}/{entity_id}")
        summary("Update a faction link")
        description("Update link metadata between a faction and another entity")
        operation_id("updateFactionLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          faction_id(:path, :string, "Faction ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["note", "character", "location", "quest", "faction"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          body(:body, Schema.ref(:LinkUpdateRequest), "Link update data", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", %{
          "type" => "object",
          "properties" => %{
            "message" => %{"type" => "string"},
            "faction_id" => %{"type" => "string", "format" => "uuid"},
            "entity_type" => %{"type" => "string"},
            "entity_id" => %{"type" => "string", "format" => "uuid"},
            "updated_at" => %{"type" => "string", "format" => "date-time"}
          }
        })

        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:ValidationError))
      end
    end
  end
end
