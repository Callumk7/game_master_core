defmodule GameMasterCoreWeb.SwaggerDefinitions do
  @moduledoc """
  Centralized Swagger schema definitions to reduce boilerplate across controllers.
  """

  import PhoenixSwagger
  alias PhoenixSwagger.Schema

  def game_schema do
    swagger_schema do
      title("Game")
      description("A game instance")

      properties do
        id(:integer, "Game ID", required: true)
        name(:string, "Game name", required: true)
        description(:string, "Game description")
        setting(:string, "Game setting")
        owner_id(:integer, "Owner user ID", required: true)
        inserted_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "My Campaign",
        description: "An epic adventure",
        setting: "Fantasy",
        owner_id: 1,
        inserted_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def game_params_schema do
    swagger_schema do
      title("Game Parameters")
      description("Parameters for creating or updating a game")

      properties do
        name(:string, "Game name", required: true)
        description(:string, "Game description")
        setting(:string, "Game setting")
      end

      required([:name])

      example(%{
        name: "My Campaign",
        description: "An epic adventure",
        setting: "Fantasy"
      })
    end
  end

  def game_request_schema do
    swagger_schema do
      title("Game Request")
      description("Game creation/update parameters")

      properties do
        game(Schema.ref(:GameParams), "Game parameters")
      end

      required([:game])
    end
  end

  def member_schema do
    swagger_schema do
      title("Member")
      description("A game member")

      properties do
        user_id(:integer, "User ID", required: true)
        email(:string, "User email", required: true)
        role(:string, "Member role", required: true)
        joined_at(:string, "Join timestamp", format: :datetime)
      end

      example(%{
        user_id: 1,
        email: "user@example.com",
        role: "member",
        joined_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entities_schema do
    swagger_schema do
      title("Entities")
      description("Collection of game entities")

      properties do
        notes(Schema.array(:object), "Notes list")
        characters(Schema.array(:object), "Characters list")
        factions(Schema.array(:object), "Factions list")
        locations(Schema.array(:object), "Locations list")
        quests(Schema.array(:object), "Quests list")
      end
    end
  end

  def entities_data_schema do
    swagger_schema do
      title("Entities Data")
      description("Game entities data structure")

      properties do
        game_id(:integer, "Game ID", required: true)
        game_name(:string, "Game name", required: true)
        entities(Schema.ref(:Entities), "Game entities")
      end
    end
  end

  # Response wrappers
  def response_schema(data_ref, title, description, example \\ nil) do
    schema =
      swagger_schema do
        title(title)
        description(description)

        properties do
          data(data_ref, "Response data")
        end
      end

    if example, do: Map.put(schema, :example, example), else: schema
  end

  def array_response_schema(item_ref, title, description, example \\ nil) do
    schema =
      swagger_schema do
        title(title)
        description(description)

        properties do
          data(Schema.array(item_ref), "Response data")
        end
      end

    if example, do: Map.put(schema, :example, example), else: schema
  end

  # Error schemas
  def error_schema do
    swagger_schema do
      title("Error")
      description("Error response")

      properties do
        errors(Schema.ref(:ErrorDetails), "Error details")
      end
    end
  end

  def error_details_schema do
    swagger_schema do
      title("Error Details")
      description("Detailed error information")
      type(:object)
    end
  end

  # Common definitions map
  def common_definitions do
    %{
      Game: game_schema(),
      GameParams: game_params_schema(),
      GameRequest: game_request_schema(),
      GameResponse:
        response_schema(Schema.ref(:Game), "Game Response", "Response containing a single game"),
      GamesResponse:
        array_response_schema(:Game, "Games Response", "Response containing a list of games"),
      Member: member_schema(),
      MembersResponse:
        array_response_schema(
          :Member,
          "Members Response",
          "Response containing a list of game members"
        ),
      Entities: entities_schema(),
      EntitiesData: entities_data_schema(),
      EntitiesResponse:
        response_schema(
          Schema.ref(:EntitiesData),
          "Entities Response",
          "Response containing all game entities"
        ),
      Error: error_schema(),
      ErrorDetails: error_details_schema()
    }
  end
end
