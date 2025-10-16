defmodule GameMasterCoreWeb.Swagger.ObjectiveSwagger do
  @moduledoc """
  Swagger documentation definitions for ObjectiveController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/quests/{quest_id}/objectives")
        summary("List objectives")
        description("Get all objectives for a quest")
        operation_id("listObjectives")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectivesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :game_objectives do
        get("/api/games/{game_id}/objectives")
        summary("List all quest objectives for a game")
        operation_id("listGameObjectives")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectivesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/quests/{quest_id}/objectives")
        summary("Create objective")
        description("Create a new objective for a quest")
        operation_id("createObjective")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          body(:body, Schema.ref(:ObjectiveCreateRequest), "Objective data", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created", Schema.ref(:ObjectiveResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/quests/{quest_id}/objectives/{id}")
        summary("Get objective")
        description("Get a single objective")
        operation_id("getObjective")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          id(:path, :string, "Objective ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectiveResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/quests/{quest_id}/objectives/{id}")
        summary("Update objective")
        description("Update an existing objective")
        operation_id("updateObjective")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          id(:path, :string, "Objective ID", required: true, format: :uuid)
          body(:body, Schema.ref(:ObjectiveUpdateRequest), "Objective data", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectiveResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/quests/{quest_id}/objectives/{id}")
        summary("Delete objective")
        description("Delete an objective")
        operation_id("deleteObjective")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          id(:path, :string, "Objective ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :complete do
        put("/api/games/{game_id}/quests/{quest_id}/objectives/{objective_id}/complete")
        summary("Complete objective")
        description("Mark an objective as complete")
        operation_id("completeObjective")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          objective_id(:path, :string, "Objective ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectiveResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :uncomplete do
        put("/api/games/{game_id}/quests/{quest_id}/objectives/{objective_id}/uncomplete")
        summary("Uncomplete objective")
        description("Mark an objective as incomplete")
        operation_id("uncompleteObjective")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          quest_id(:path, :string, "Quest ID", required: true, format: :uuid)
          objective_id(:path, :string, "Objective ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:ObjectiveResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end
    end
  end
end
