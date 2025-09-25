defmodule GameMasterCoreWeb.Swagger.PinnedSwagger do
  @moduledoc """
  Swagger documentation definitions for PinnedController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/pinned")
        summary("Get all pinned entities")

        description(
          "Get all pinned entities (characters, notes, factions, locations, quests) for a game"
        )

        operation_id("listPinnedEntities")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:PinnedEntitiesResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end
    end
  end
end
