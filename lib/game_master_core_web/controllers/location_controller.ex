defmodule GameMasterCoreWeb.LocationController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Locations
  alias GameMasterCore.Locations.Location
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :index do
    get("/api/games/{game_id}/locations")
    summary("List locations")
    description("Get all locations in a game")
    operation_id("listLocations")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:LocationsResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def index(conn, _params) do
    locations = Locations.list_locations_for_game(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  swagger_path :create do
    post("/api/games/{game_id}/locations")
    summary("Create location")
    description("Create a new location in the game")
    operation_id("createLocation")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      body(:body, Schema.ref(:LocationRequest), "Location to create", required: true)
    end

    security([%{Bearer: []}])

    response(201, "Created", Schema.ref(:LocationResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create(conn, %{"location" => location_params}) do
    with {:ok, %Location{} = location} <-
           Locations.create_location_for_game(conn.assigns.current_scope, location_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/locations/#{location}"
      )
      |> render(:show, location: location)
    end
  end

  swagger_path :show do
    get("/api/games/{game_id}/locations/{id}")
    summary("Get location")
    description("Get a specific location by ID")
    operation_id("getLocation")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Location ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:LocationResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, location: location)
  end

  swagger_path :update do
    put("/api/games/{game_id}/locations/{id}")
    summary("Update location")
    description("Update an existing location")
    operation_id("updateLocation")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Location ID", required: true)
      body(:body, Schema.ref(:LocationRequest), "Location updates", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:LocationResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Location{} = location} <-
           Locations.update_location(conn.assigns.current_scope, location, location_params) do
      render(conn, :show, location: location)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/locations/{id}")
    summary("Delete location")
    description("Delete a location from the game")
    operation_id("deleteLocation")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      id(:path, :integer, "Location ID", required: true)
    end

    security([%{Bearer: []}])

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Location{}} <- Locations.delete_location(conn.assigns.current_scope, location) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :create_link do
    post("/api/games/{game_id}/locations/{location_id}/links")
    summary("Create location link")
    description("Link a location to another entity (note, faction, etc.)")
    operation_id("createLocationLink")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      location_id(:path, :integer, "Location ID", required: true)

      entity_type(:query, :string, "Entity type to link",
        required: true,
        enum: ["character", "faction", "location", "quest", "note"]
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

  def create_link(conn, %{"location_id" => location_id} = params) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, location_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_location_link(conn.assigns.current_scope, location.id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        location_id: location.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  swagger_path :list_links do
    get("/api/games/{game_id}/locations/{location_id}/links")
    summary("Get location links")
    description("Get all entities linked to a location")
    operation_id("getLocationLinks")
    tag("GameMaster")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      location_id(:path, :integer, "Location ID", required: true)
    end

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:LocationLinksResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_links(conn, %{"location_id" => location_id}) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, location_id)

    links = Locations.links(conn.assigns.current_scope, location.id)

    render(conn, :links,
      location: location,
      notes: links.notes,
      factions: links.factions,
      characters: links.characters,
      quests: links.quests
    )
  end

  swagger_path :delete_link do
    PhoenixSwagger.Path.delete(
      "/api/games/{game_id}/locations/{location_id}/links/{entity_type}/{entity_id}"
    )

    summary("Delete location link")
    operation_id("deleteLocationLink")
    tag("GameMaster")
    description("Remove a link between a location and another entity")

    parameters do
      game_id(:path, :integer, "Game ID", required: true)
      location_id(:path, :integer, "Location ID", required: true)
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
        "location_id" => location_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    location = Locations.get_location_for_game!(conn.assigns.current_scope, location_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_location_link(conn.assigns.current_scope, location.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_location_link(scope, location_id, :note, note_id) do
    Locations.link_note(scope, location_id, note_id)
  end

  defp create_location_link(scope, location_id, :faction, faction_id) do
    Locations.link_faction(scope, location_id, faction_id)
  end

  defp create_location_link(_scope, _location_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  defp delete_location_link(scope, location_id, :note, note_id) do
    Locations.unlink_note(scope, location_id, note_id)
  end

  defp delete_location_link(scope, location_id, :faction, faction_id) do
    Locations.unlink_faction(scope, location_id, faction_id)
  end

  defp delete_location_link(_scope, _location_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end
end
