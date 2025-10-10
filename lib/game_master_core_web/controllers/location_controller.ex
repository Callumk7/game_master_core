defmodule GameMasterCoreWeb.LocationController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Locations
  alias GameMasterCore.Locations.Location
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.LocationSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    locations = Locations.list_locations_for_game(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  def tree(conn, _params) do
    tree = Locations.list_locations_tree_for_game(conn.assigns.current_scope)
    render(conn, :tree, tree: tree)
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

  def show(conn, %{"id" => id}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, location: location)
    end
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id),
         {:ok, %Location{} = location} <-
           Locations.update_location(conn.assigns.current_scope, location, location_params) do
      render(conn, :show, location: location)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id),
         {:ok, %Location{}} <- Locations.delete_location(conn.assigns.current_scope, location) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_link(conn, %{"location_id" => location_id} = params) do
    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    # Extract metadata fields, excluding nils to use schema defaults
    metadata_attrs =
      %{
        relationship_type: Map.get(params, "relationship_type"),
        description: Map.get(params, "description"),
        strength: Map.get(params, "strength"),
        is_active: Map.get(params, "is_active"),
        is_current_location: Map.get(params, "is_current_location"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_location_link(
             conn.assigns.current_scope,
             location.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
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

  def list_links(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id) do
      links = Locations.links(conn.assigns.current_scope, location_id)

      render(conn, :links,
        location: location,
        notes: links.notes,
        factions: links.factions,
        characters: links.characters,
        quests: links.quests,
        locations: links.locations
      )
    end
  end

  def delete_link(conn, %{
        "location_id" => location_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_location_link(conn.assigns.current_scope, location.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def update_link(
        conn,
        %{
          "location_id" => location_id,
          "entity_type" => entity_type,
          "entity_id" => entity_id
        } = params
      ) do
    # Extract metadata fields, excluding nils to preserve existing values
    metadata_attrs =
      %{
        relationship_type: Map.get(params, "relationship_type"),
        description: Map.get(params, "description"),
        strength: Map.get(params, "strength"),
        is_active: Map.get(params, "is_active"),
        is_current_location: Map.get(params, "is_current_location"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_location_link(
             conn.assigns.current_scope,
             location.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        location_id: location.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
    end
  end

  # Private helpers for link management

  defp create_location_link(scope, location_id, :note, note_id, metadata_attrs) do
    Locations.link_note(scope, location_id, note_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :faction, faction_id, metadata_attrs) do
    Locations.link_faction(scope, location_id, faction_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :character, character_id, metadata_attrs) do
    Locations.link_character(scope, location_id, character_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :quest, quest_id, metadata_attrs) do
    Locations.link_quest(scope, location_id, quest_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :location, other_location_id, metadata_attrs) do
    Locations.link_location(scope, location_id, other_location_id, metadata_attrs)
  end

  defp create_location_link(_scope, _location_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  defp delete_location_link(scope, location_id, :note, note_id) do
    Locations.unlink_note(scope, location_id, note_id)
  end

  defp delete_location_link(scope, location_id, :faction, faction_id) do
    Locations.unlink_faction(scope, location_id, faction_id)
  end

  defp delete_location_link(scope, location_id, :character, character_id) do
    Locations.unlink_character(scope, location_id, character_id)
  end

  defp delete_location_link(scope, location_id, :quest, quest_id) do
    Locations.unlink_quest(scope, location_id, quest_id)
  end

  defp delete_location_link(scope, location_id, :location, other_location_id) do
    Locations.unlink_location(scope, location_id, other_location_id)
  end

  defp delete_location_link(_scope, _location_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  defp update_location_link(scope, location_id, :note, note_id, metadata_attrs) do
    Locations.update_link_note(scope, location_id, note_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :character, character_id, metadata_attrs) do
    Locations.update_link_character(scope, location_id, character_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :faction, faction_id, metadata_attrs) do
    Locations.update_link_faction(scope, location_id, faction_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :quest, quest_id, metadata_attrs) do
    Locations.update_link_quest(scope, location_id, quest_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :location, other_location_id, metadata_attrs) do
    Locations.update_link_location(scope, location_id, other_location_id, metadata_attrs)
  end

  defp update_location_link(_scope, _location_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  # Pinning endpoints

  def pin(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, updated_location} <- Locations.pin_location(conn.assigns.current_scope, location) do
      render(conn, :show, location: updated_location)
    end
  end

  def unpin(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, updated_location} <- Locations.unpin_location(conn.assigns.current_scope, location) do
      render(conn, :show, location: updated_location)
    end
  end
end
