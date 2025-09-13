defmodule GameMasterCoreWeb.FactionController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Factions
  alias GameMasterCore.Factions.Faction
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :index do
    get("/api/games/{game_id}/factions")
    summary("List factions")
    description("Get all factions in a game")
    operation_id("listFactions")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:FactionsResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def index(conn, _params) do
    factions = Factions.list_factions_for_game(conn.assigns.current_scope)
    render(conn, :index, factions: factions)
  end

  swagger_path :create do
    post("/api/games/{game_id}/factions")
    summary("Create faction")
    description("Create a new faction in the game")
    operation_id("createFaction")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      body(:body, Schema.ref(:FactionRequest), "Faction to create", required: true)
    end

    security([%{Bearer: []}])

    response(201, "Created", Schema.ref(:FactionResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create(conn, %{"faction" => faction_params}) do
    with {:ok, %Faction{} = faction} <-
           Factions.create_faction_for_game(conn.assigns.current_scope, faction_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/factions/#{faction}"
      )
      |> render(:show, faction: faction)
    end
  end

  swagger_path :show do
    get("/api/games/{game_id}/factions/{id}")
    summary("Get faction")
    description("Get a specific faction by ID")
    operation_id("getFaction")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Faction ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:FactionResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, faction: faction)
  end

  swagger_path :update do
    put("/api/games/{game_id}/factions/{id}")
    summary("Update faction")
    description("Update an existing faction")
    operation_id("updateFaction")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Faction ID", required: true)
      body(:body, Schema.ref(:FactionRequest), "Faction updates", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:FactionResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "faction" => faction_params}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Faction{} = faction} <-
           Factions.update_faction(conn.assigns.current_scope, faction, faction_params) do
      render(conn, :show, faction: faction)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/factions/{id}")
    summary("Delete faction")
    description("Delete a faction from the game")
    operation_id("deleteFaction")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Faction ID", required: true)
    end

    security([%{Bearer: []}])

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Faction{}} <- Factions.delete_faction(conn.assigns.current_scope, faction) do
      send_resp(conn, :no_content, "")
    end
  end

  # Faction Links

  swagger_path :create_link do
    post("/api/games/{game_id}/factions/{faction_id}/links")
    summary("Create faction link")
    description("Link a faction to another entity (note, character, etc.)")
    operation_id("createFactionLink")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      faction_id(:path, :integer, "Faction ID", required: true)

      entity_type(:query, :string, "Entity type to link",
        required: true,
        enum: ["character", "location", "quest", "note"]
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

  def create_link(conn, %{"faction_id" => faction_id} = params) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, faction_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_faction_link(conn.assigns.current_scope, faction.id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        faction_id: faction.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  swagger_path :list_links do
    get("/api/games/{game_id}/factions/{faction_id}/links")
    summary("Get faction links")
    description("Get all entities linked to a faction")
    operation_id("getFactionLinks")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      faction_id(:path, :integer, "Faction ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:FactionLinksResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_links(conn, %{"faction_id" => faction_id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, faction_id)

    notes = Factions.linked_notes(conn.assigns.current_scope, faction_id)
    characters = Factions.linked_characters(conn.assigns.current_scope, faction_id)
    quests = Factions.linked_quests(conn.assigns.current_scope, faction_id)
    locations = Factions.linked_locations(conn.assigns.current_scope, faction_id)

    render(conn, :links,
      faction: faction,
      notes: notes,
      characters: characters,
      locations: locations,
      quests: quests
    )
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
      game_id(:path, :integer, "Game ID", required: true)
      faction_id(:path, :integer, "Faction ID", required: true)
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
        "faction_id" => faction_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, faction_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_faction_link(conn.assigns.current_scope, faction.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_faction_link(scope, faction_id, :note, note_id) do
    Factions.link_note(scope, faction_id, note_id)
  end

  defp create_faction_link(scope, faction_id, :character, character_id) do
    Factions.link_character(scope, faction_id, character_id)
  end

  defp create_faction_link(scope, faction_id, :location, location_id) do
    Factions.link_location(scope, faction_id, location_id)
  end

  defp create_faction_link(scope, faction_id, :quest, quest_id) do
    Factions.link_quest(scope, faction_id, quest_id)
  end

  defp create_faction_link(_scope, _faction_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end

  defp delete_faction_link(scope, faction_id, :note, note_id) do
    Factions.unlink_note(scope, faction_id, note_id)
  end

  defp delete_faction_link(scope, faction_id, :character, character_id) do
    Factions.unlink_character(scope, faction_id, character_id)
  end

  defp delete_faction_link(scope, faction_id, :location, location_id) do
    Factions.unlink_location(scope, faction_id, location_id)
  end

  defp delete_faction_link(scope, faction_id, :quest, quest_id) do
    Factions.unlink_quest(scope, faction_id, quest_id)
  end

  defp delete_faction_link(_scope, _faction_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end
end
