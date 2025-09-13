defmodule GameMasterCoreWeb.QuestController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Quests
  alias GameMasterCore.Quests.Quest
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :index do
    get("/api/games/{game_id}/quests")
    summary("List quests")
    description("Get all quests in a game")
    operation_id("listQuests")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:QuestsResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def index(conn, _params) do
    quests = Quests.list_quests_for_game(conn.assigns.current_scope)
    render(conn, :index, quests: quests)
  end

  swagger_path :create do
    post("/api/games/{game_id}/quests")
    summary("Create quest")
    description("Create a new quest in the game")
    operation_id("createQuest")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      body(:body, Schema.ref(:QuestRequest), "Quest to create", required: true)
    end

    security([%{Bearer: []}])

    response(201, "Created", Schema.ref(:QuestResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create(conn, %{"quest" => quest_params}) do
    with {:ok, %Quest{} = quest} <-
           Quests.create_quest_for_game(conn.assigns.current_scope, quest_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/quests/#{quest}"
      )
      |> render(:show, quest: quest)
    end
  end

  swagger_path :show do
    get("/api/games/{game_id}/quests/{id}")
    summary("Get quest")
    description("Get a specific quest by ID")
    operation_id("getQuest")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Quest ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:QuestResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, quest: quest)
  end

  swagger_path :update do
    put("/api/games/{game_id}/quests/{id}")
    summary("Update quest")
    description("Update an existing quest")
    operation_id("updateQuest")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Quest ID", required: true)
      body(:body, Schema.ref(:QuestRequest), "Quest updates", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:QuestResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "quest" => quest_params}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Quest{} = quest} <-
           Quests.update_quest(conn.assigns.current_scope, quest, quest_params) do
      render(conn, :show, quest: quest)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/quests/{id}")
    summary("Delete quest")
    description("Delete a quest from the game")
    operation_id("deleteQuest")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Quest ID", required: true)
    end

    security([%{Bearer: []}])

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Quest{}} <- Quests.delete_quest(conn.assigns.current_scope, quest) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :create_link do
    post("/api/games/{game_id}/quests/{quest_id}/links")
    summary("Create quest link")
    description("Link a quest to another entity (note, character, faction, location)")
    operation_id("createQuestLink")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      quest_id(:path, :integer, "Quest ID", required: true)

      entity_type(:query, :string, "Entity type to link",
        required: true,
        enum: ["character", "faction", "location", "note"]
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

  def create_link(conn, %{"quest_id" => quest_id} = params) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, quest_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_quest_link(conn.assigns.current_scope, quest.id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        quest_id: quest.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  swagger_path :list_links do
    get("/api/games/{game_id}/quests/{quest_id}/links")
    summary("Get quest links")
    description("Get all entities linked to a quest")
    operation_id("getQuestLinks")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      quest_id(:path, :integer, "Quest ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:QuestLinksResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_links(conn, %{"quest_id" => quest_id}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, quest_id)

    links = Quests.links(conn.assigns.current_scope, quest.id)

    render(conn, :links,
      quest: quest,
      characters: links.characters,
      factions: links.factions,
      notes: links.notes,
      locations: links.locations
    )
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
      game_id(:path, :integer, "Game ID", required: true)
      quest_id(:path, :integer, "Quest ID", required: true)
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
        "quest_id" => quest_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, quest_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_quest_link(conn.assigns.current_scope, quest.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  defp create_quest_link(scope, quest_id, :character, character_id) do
    Quests.link_character(scope, quest_id, character_id)
  end

  defp create_quest_link(scope, quest_id, :faction, faction_id) do
    Quests.link_faction(scope, quest_id, faction_id)
  end

  defp create_quest_link(scope, quest_id, :note, note_id) do
    Quests.link_note(scope, quest_id, note_id)
  end

  defp create_quest_link(scope, quest_id, :location, location_id) do
    Quests.link_location(scope, quest_id, location_id)
  end

  defp create_quest_link(_scope, _quest_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :quest, entity_type}}
  end

  defp delete_quest_link(scope, quest_id, :character, character_id) do
    Quests.unlink_character(scope, quest_id, character_id)
  end

  defp delete_quest_link(scope, quest_id, :faction, faction_id) do
    Quests.unlink_faction(scope, quest_id, faction_id)
  end

  defp delete_quest_link(scope, quest_id, :note, note_id) do
    Quests.unlink_note(scope, quest_id, note_id)
  end

  defp delete_quest_link(scope, quest_id, :location, location_id) do
    Quests.unlink_location(scope, quest_id, location_id)
  end

  defp delete_quest_link(_scope, _quest_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :quest, entity_type}}
  end
end
