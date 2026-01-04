defmodule GameMasterCoreWeb.Swagger.SearchSwagger do
  @moduledoc """
  Swagger documentation definitions for SearchController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :search do
        get("/api/games/{game_id}/search")
        summary("Search game entities")

        description("""
        Search across all entity types (characters, factions, locations, quests, notes) within a game.
        Results are grouped by entity type and sorted by pinned status (pinned first) then by name.
        Supports filtering by entity types, tags (AND logic), and pinned status.
        """)

        operation_id("searchGame")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          q(:query, :string, "Search query (searches name and content)",
            required: true,
            example: "dragon"
          )

          types(:query, :string, "Comma-separated entity types to search",
            required: false,
            example: "character,faction,location"
          )

          tags(:query, :string, "Comma-separated tags (AND logic - all must match)",
            required: false,
            example: "npc,villain"
          )

          pinned_only(:query, :boolean, "Only return pinned entities",
            required: false,
            default: false
          )

          limit(:query, :integer, "Maximum results per entity type (default: 50, max: 100)",
            required: false,
            default: 50
          )

          offset(:query, :integer, "Pagination offset (default: 0)",
            required: false,
            default: 0
          )
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:SearchResponse))
        response(400, "Bad Request - Missing or invalid query parameter", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found - Game not found", Schema.ref(:Error))
      end
    end
  end
end
