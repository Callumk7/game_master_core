defmodule GameMasterCoreWeb.Swagger.QuestSwagger do
  @moduledoc """
  Swagger documentation definitions for QuestController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/quests")
        summary("List quests")
        description("Get all quests in a game")
        operation_id("listQuests")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:QuestsResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/quests")
        summary("Create quest")
        description("Create a new quest in the game")
        operation_id("createQuest")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:QuestCreateRequest), "Quest to create", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created", Schema.ref(:QuestResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/quests/{id}")
        summary("Get quest")
        description("Get a specific quest by ID")
        operation_id("getQuest")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Quest ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:QuestResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/quests/{id}")
        summary("Update quest")
        description("Update an existing quest")
        operation_id("updateQuest")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Quest ID", required: true, format: :uuid)
          body(:body, Schema.ref(:QuestUpdateRequest), "Quest updates", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:QuestResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/quests/{id}")
        summary("Delete quest")
        description("Delete a quest from the game")
        operation_id("deleteQuest")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Quest ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create_link do
        post("/api/games/{game_id}/quests/{quest_id}/links")
        summary("Create quest link")
        description("Link a quest to another entity (note, character, faction, location)")
        operation_id("createQuestLink")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)

          entity_type(:query, :string, "Entity type to link",
            required: true,
            enum: ["character", "faction", "location", "note", "quest"]
          )

          entity_id(:query, :string, "Entity ID to link", required: true, format: :uuid)
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
        get("/api/games/{game_id}/quests/{quest_id}/links")
        summary("Get quest links")
        description("Get all entities linked to a quest")
        operation_id("getQuestLinks")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:QuestLinksResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :delete_link do
        PhoenixSwagger.Path.delete(
          "/api/games/{game_id}/quests/{quest_id}/links/{entity_type}/{entity_id}"
        )

        summary("Delete quest link")
        operation_id("deleteQuestLink")
        tag("GameMaster")
        description("Remove a link between a quest and another entity")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "note", "quest"]
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
    end
  end
end
