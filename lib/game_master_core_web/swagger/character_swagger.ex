defmodule GameMasterCoreWeb.Swagger.CharacterSwagger do
  @moduledoc """
  Swagger documentation definitions for CharacterController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/characters")
        summary("List characters")
        description("Get all characters in a game")
        operation_id("listCharacters")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharactersResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/characters")
        summary("Create character")

        description(
          "Create a new character in the game with optional entity links (factions, locations, etc.)"
        )

        operation_id("createCharacter")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          body(:body, Schema.ref(:CharacterCreateRequest), "Character to create", required: true)
        end

        security([%{Bearer: []}])

        response(201, "Created", Schema.ref(:CharacterResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/characters/{id}")
        summary("Get character")
        description("Get a specific character by ID")
        operation_id("getCharacter")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/characters/{id}")
        summary("Update character")
        description("Update an existing character")
        operation_id("updateCharacter")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Character ID", required: true, format: :uuid)
          body(:body, Schema.ref(:CharacterUpdateRequest), "Character updates", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/characters/{id}")
        summary("Delete character")
        description("Delete a character from the game")
        operation_id("deleteCharacter")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create_link do
        post("/api/games/{game_id}/characters/{character_id}/links")
        summary("Create character link")
        description("Link a character to another entity (note, faction, etc.)")
        operation_id("createCharacterLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)

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
        get("/api/games/{game_id}/characters/{character_id}/links")
        summary("Get character links")
        description("Get all entities linked to a character")
        operation_id("getCharacterLinks")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterLinksResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :delete_link do
        PhoenixSwagger.Path.delete(
          "/api/games/{game_id}/characters/{character_id}/links/{entity_type}/{entity_id}"
        )

        summary("Delete character link")
        description("Remove a link between a character and another entity")
        operation_id("deleteCharacterLink")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["note", "faction", "location", "quest", "character"]
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

      swagger_path :get_primary_faction do
        get("/api/games/{game_id}/characters/{character_id}/primary-faction")
        summary("Get character's primary faction")
        description("Get the primary faction details for a character")
        operation_id("getCharacterPrimaryFaction")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterPrimaryFactionResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :set_primary_faction do
        post("/api/games/{game_id}/characters/{character_id}/primary-faction")
        summary("Set character's primary faction")

        description(
          "Set or update a character's primary faction and role, automatically syncing with CharacterFaction relationship"
        )

        operation_id("setCharacterPrimaryFaction")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)

          body(:body, Schema.ref(:SetPrimaryFactionRequest), "Primary faction data",
            required: true
          )
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :remove_primary_faction do
        PhoenixSwagger.Path.delete(
          "/api/games/{game_id}/characters/{character_id}/primary-faction"
        )

        summary("Remove character's primary faction")

        description(
          "Remove a character's primary faction while preserving the CharacterFaction relationship record"
        )

        operation_id("removeCharacterPrimaryFaction")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :pin do
        PhoenixSwagger.Path.put("/api/games/{game_id}/characters/{character_id}/pin")
        summary("Pin character")
        description("Pin a character for quick access")
        operation_id("pinCharacter")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :unpin do
        PhoenixSwagger.Path.put("/api/games/{game_id}/characters/{character_id}/unpin")
        summary("Unpin character")
        description("Unpin a character")
        operation_id("unpinCharacter")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)
        end

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:CharacterResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(403, "Forbidden", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update_link do
        put("/api/games/{game_id}/characters/{character_id}/links/{entity_type}/{entity_id}")
        summary("Update a character link")
        description("Update link metadata between a character and another entity")
        operation_id("updateCharacterLink")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          character_id(:path, :string, "Character ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["note", "faction", "location", "quest", "character"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          body(:body, Schema.ref(:LinkUpdateRequest), "Link update data", required: true)
        end

        security([%{Bearer: []}])

        response(200, "Success", %{
          "type" => "object",
          "properties" => %{
            "message" => %{"type" => "string"},
            "character_id" => %{"type" => "string", "format" => "uuid"},
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
