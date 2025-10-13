defmodule GameMasterCoreWeb.FactionController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Factions
  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Notes
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.FactionSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    factions = Factions.list_factions_for_game(conn.assigns.current_scope)
    render(conn, :index, factions: factions)
  end

  def create(conn, %{"faction" => faction_params, "links" => links}) when is_list(links) do
    with {:ok, %Faction{} = faction} <-
           Factions.create_faction_with_links(conn.assigns.current_scope, faction_params, links) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/factions/#{faction}"
      )
      |> render(:show, faction: faction)
    end
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

  def show(conn, %{"id" => id}) do
    with {:ok, faction} <- Factions.fetch_faction_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, faction: faction)
    end
  end

  def update(conn, %{"id" => id, "faction" => faction_params}) do
    with {:ok, faction} <- Factions.fetch_faction_for_game(conn.assigns.current_scope, id),
         {:ok, %Faction{} = faction} <-
           Factions.update_faction(conn.assigns.current_scope, faction, faction_params) do
      render(conn, :show, faction: faction)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, faction} <- Factions.fetch_faction_for_game(conn.assigns.current_scope, id),
         {:ok, %Faction{}} <- Factions.delete_faction(conn.assigns.current_scope, faction) do
      send_resp(conn, :no_content, "")
    end
  end

  def notes_tree(conn, params) do
    faction_id = params["faction_id"] || params["id"]

    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id) do
      notes_tree =
        Notes.list_faction_notes_tree_for_game(conn.assigns.current_scope, faction.id)

      render(conn, :notes_tree, faction: faction, notes_tree: notes_tree)
    end
  end

  def create_link(conn, %{"faction_id" => faction_id} = params) do
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
        is_primary: Map.get(params, "is_primary"),
        faction_role: Map.get(params, "faction_role"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_faction_link(
             conn.assigns.current_scope,
             faction.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
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

  def list_links(conn, %{"faction_id" => faction_id}) do
    with {:ok, faction} <- Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id) do
      links = Factions.links(conn.assigns.current_scope, faction_id)

      render(conn, :links,
        faction: faction,
        notes: links.notes,
        characters: links.characters,
        locations: links.locations,
        quests: links.quests,
        factions: links.factions
      )
    end
  end

  def members(conn, %{"faction_id" => faction_id}) do
    with {:ok, faction} <- Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id) do
      members = Factions.list_faction_members(conn.assigns.current_scope, faction_id)
      render(conn, :members, faction: faction, members: members)
    end
  end

  def delete_link(conn, %{
        "faction_id" => faction_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_faction_link(conn.assigns.current_scope, faction.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def update_link(
        conn,
        %{
          "faction_id" => faction_id,
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
        is_primary: Map.get(params, "is_primary"),
        faction_role: Map.get(params, "faction_role"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_faction_link(
             conn.assigns.current_scope,
             faction.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        faction_id: faction.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
    end
  end

  # Private helpers for link management

  defp create_faction_link(scope, faction_id, :note, note_id, metadata_attrs) do
    Factions.link_note(scope, faction_id, note_id, metadata_attrs)
  end

  defp create_faction_link(scope, faction_id, :character, character_id, metadata_attrs) do
    Factions.link_character(scope, faction_id, character_id, metadata_attrs)
  end

  defp create_faction_link(scope, faction_id, :location, location_id, metadata_attrs) do
    Factions.link_location(scope, faction_id, location_id, metadata_attrs)
  end

  defp create_faction_link(scope, faction_id, :quest, quest_id, metadata_attrs) do
    Factions.link_quest(scope, faction_id, quest_id, metadata_attrs)
  end

  defp create_faction_link(scope, faction_id, :faction, other_faction_id, metadata_attrs) do
    Factions.link_faction(scope, faction_id, other_faction_id, metadata_attrs)
  end

  defp create_faction_link(_scope, _faction_id, entity_type, _entity_id, _metadata_attrs) do
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

  defp delete_faction_link(scope, faction_id, :faction, other_faction_id) do
    Factions.unlink_faction(scope, faction_id, other_faction_id)
  end

  defp delete_faction_link(_scope, _faction_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end

  defp update_faction_link(scope, faction_id, :note, note_id, metadata_attrs) do
    Factions.update_link_note(scope, faction_id, note_id, metadata_attrs)
  end

  defp update_faction_link(scope, faction_id, :character, character_id, metadata_attrs) do
    Factions.update_link_character(scope, faction_id, character_id, metadata_attrs)
  end

  defp update_faction_link(scope, faction_id, :location, location_id, metadata_attrs) do
    Factions.update_link_location(scope, faction_id, location_id, metadata_attrs)
  end

  defp update_faction_link(scope, faction_id, :quest, quest_id, metadata_attrs) do
    Factions.update_link_quest(scope, faction_id, quest_id, metadata_attrs)
  end

  defp update_faction_link(scope, faction_id, :faction, other_faction_id, metadata_attrs) do
    Factions.update_link_faction(scope, faction_id, other_faction_id, metadata_attrs)
  end

  defp update_faction_link(_scope, _faction_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end

  # Pinning endpoints

  def pin(conn, %{"faction_id" => faction_id}) do
    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id),
         {:ok, updated_faction} <- Factions.pin_faction(conn.assigns.current_scope, faction) do
      render(conn, :show, faction: updated_faction)
    end
  end

  def unpin(conn, %{"faction_id" => faction_id}) do
    with {:ok, faction} <-
           Factions.fetch_faction_for_game(conn.assigns.current_scope, faction_id),
         {:ok, updated_faction} <- Factions.unpin_faction(conn.assigns.current_scope, faction) do
      render(conn, :show, faction: updated_faction)
    end
  end
end
