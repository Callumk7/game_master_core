defmodule GameMasterCoreWeb.Swagger.GameSwagger do
  @moduledoc """
  Swagger documentation definitions for GameController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games")
        summary("List all games")
        description("Retrieve a list of all games accessible to the current user")
        operation_id("listGames")
        tag("GameMaster")
        produces("application/json")

        parameters do
        end

        response(200, "Success", Schema.ref(:GamesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games")
        summary("Create a new game")
        description("Create a new game with the provided parameters")
        operation_id("createGame")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          body(:body, Schema.ref(:GameCreateRequest), "Game parameters", required: true)
        end

        response(201, "Created", Schema.ref(:GameResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{id}")
        summary("Get a game")
        description("Retrieve a specific game by its ID")
        operation_id("getGame")
        tag("GameMaster")
        produces("application/json")

        parameters do
          id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:GameResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{id}")
        summary("Update a game")
        description("Update a specific game with the provided parameters")
        operation_id("updateGame")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:GameUpdateRequest), "Game parameters", required: true)
        end

        response(200, "Success", Schema.ref(:GameResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{id}")
        summary("Delete a game")
        description("Delete a specific game by its ID")
        operation_id("deleteGame")
        tag("GameMaster")

        parameters do
          id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :add_member do
        post("/api/games/{game_id}/members")
        summary("Add a member to a game")
        description("Add a user as a member to the specified game")
        operation_id("addGameMember")
        tag("GameMaster")
        consumes("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          user_id(:formData, :integer, "User ID to add", required: true)
          role(:formData, :string, "Member role (default: 'member')")
        end

        response(201, "Created")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :remove_member do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/members/{user_id}")
        summary("Remove a member from a game")
        description("Remove a user from the specified game")
        operation_id("removeGameMember")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          user_id(:path, :integer, "User ID to remove", required: true)
        end

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :list_members do
        get("/api/games/{game_id}/members")
        summary("List game members")
        description("Retrieve a list of all members in the specified game")
        operation_id("listGameMembers")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:MembersResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :list_entities do
        get("/api/games/{game_id}/links")
        summary("List game entities")

        description(
          "Retrieve all entities (notes, characters, factions, locations, quests) for the specified game"
        )

        operation_id("listGameEntities")

        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:EntitiesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :tree do
        get("/api/games/{game_id}/tree")
        summary("Get entity tree")
        description("Get comprehensive hierarchical tree of entity relationships within a game")
        operation_id("getGameEntityTree")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          depth(:query, :integer, "Maximum depth to traverse (default: 3, max: 10)",
            required: false
          )

          start_entity_type(
            :query,
            :string,
            "Entity type to start from (character, faction, location, quest, note)",
            required: false
          )

          start_entity_id(:query, :string, "Entity ID to start from (requires start_entity_type)",
            required: false,
            format: :uuid
          )
        end

        response(200, "Success", Schema.ref(:EntityTreeResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end
    end
  end
end
