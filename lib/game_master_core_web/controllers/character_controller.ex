defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :index do
    get("/api/games/{game_id}/characters")
    summary("List characters")
    description("Get all characters in a game")
    operation_id("listCharacters")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:CharactersResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def index(conn, _params) do
    characters = Characters.list_characters_for_game(conn.assigns.current_scope)
    render(conn, :index, characters: characters)
  end

  swagger_path :create do
    post("/api/games/{game_id}/characters")
    summary("Create character")
    description("Create a new character in the game")
    operation_id("createCharacter")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      body(:body, Schema.ref(:CharacterRequest), "Character to create", required: true)
    end

    security([%{Bearer: []}])

    response(201, "Created", Schema.ref(:CharacterResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create(conn, %{"character" => character_params}) do
    with {:ok, %Character{} = character} <-
           Characters.create_character_for_game(
             conn.assigns.current_scope,
             character_params
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/characters/#{character}"
      )
      |> render(:show, character: character)
    end
  end

  swagger_path :show do
    get("/api/games/{game_id}/characters/{id}")
    summary("Get character")
    description("Get a specific character by ID")
    operation_id("getCharacter")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Character ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:CharacterResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, character: character)
  end

  swagger_path :update do
    put("/api/games/{game_id}/characters/{id}")
    summary("Update character")
    description("Update an existing character")
    operation_id("updateCharacter")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Character ID", required: true)
      body(:body, Schema.ref(:CharacterRequest), "Character updates", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:CharacterResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Character{} = character} <-
           Characters.update_character(conn.assigns.current_scope, character, character_params) do
      render(conn, :show, character: character)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/characters/{id}")
    summary("Delete character")
    description("Delete a character from the game")
    operation_id("deleteCharacter")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Character ID", required: true)
    end

    security([%{Bearer: []}])

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Character{}} <- Characters.delete_character(conn.assigns.current_scope, character) do
      send_resp(conn, :no_content, "")
    end
  end

  # Character Links

  swagger_path :create_link do
    post("/api/games/{game_id}/characters/{character_id}/links")
    summary("Create character link")
    description("Link a character to another entity (note, faction, etc.)")
    operation_id("createCharacterLink")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      character_id(:path, :integer, "Character ID", required: true)

      entity_type(:query, :string, "Entity type to link",
        required: true,
        enum: ["faction", "location", "quest", "note"]
      )

      entity_id(:query, :integer, "Entity ID to link", required: true)
    end

    security([%{Bearer: []}])

    response(201, "Created")
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create_link(conn, %{"character_id" => character_id} = params) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_character_link(conn.assigns.current_scope, character_id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        character_id: character.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  swagger_path :list_links do
    get("/api/games/{game_id}/characters/{character_id}/links")
    summary("Get character links")
    description("Get all entities linked to a character")
    operation_id("getCharacterLinks")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      character_id(:path, :integer, "Character ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:CharacterLinksResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_links(conn, %{"character_id" => character_id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

    links = Characters.links(conn.assigns.current_scope, character_id)

    render(conn, :links,
      character: character,
      notes: links.notes,
      factions: links.factions,
      locations: links.locations,
      quests: links.quests
    )
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
      game_id(:path, :integer, "Game ID", required: true)
      character_id(:path, :integer, "Character ID", required: true)
      entity_type(:path, :string, "Entity type", required: true)
      entity_id(:path, :integer, "Entity ID", required: true)
    end

    security([%{Bearer: []}])

    response(204, "No Content")
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete_link(conn, %{
        "character_id" => character_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_character_link(conn.assigns.current_scope, character.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_character_link(scope, character_id, :note, note_id) do
    Characters.link_note(scope, character_id, note_id)
  end

  defp create_character_link(scope, character_id, :faction, faction_id) do
    Characters.link_faction(scope, character_id, faction_id)
  end

  defp create_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end

  defp delete_character_link(scope, character_id, :note, note_id) do
    Characters.unlink_note(scope, character_id, note_id)
  end

  defp delete_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end
end
