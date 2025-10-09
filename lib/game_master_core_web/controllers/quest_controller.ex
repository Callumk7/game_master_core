defmodule GameMasterCoreWeb.QuestController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Quests
  alias GameMasterCore.Quests.Quest
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.QuestSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    quests = Quests.list_quests_for_game(conn.assigns.current_scope)
    render(conn, :index, quests: quests)
  end

  def tree(conn, _params) do
    tree = Quests.list_quests_tree_for_game(conn.assigns.current_scope)
    render(conn, :tree, tree: tree)
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

  def show(conn, %{"id" => id}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, quest: quest)
    end
  end

  def update(conn, %{"id" => id, "quest" => quest_params}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, id),
         {:ok, %Quest{} = quest} <-
           Quests.update_quest(conn.assigns.current_scope, quest, quest_params) do
      render(conn, :show, quest: quest)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, id),
         {:ok, %Quest{}} <- Quests.delete_quest(conn.assigns.current_scope, quest) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_link(conn, %{"quest_id" => quest_id} = params) do
    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    # Extract metadata fields, excluding nils to use schema defaults
    metadata_attrs = 
      %{
        relationship_type: Map.get(params, "relationship_type"),
        description: Map.get(params, "description"),
        strength: Map.get(params, "strength"),
        is_active: Map.get(params, "is_active"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_quest_link(
             conn.assigns.current_scope,
             quest.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
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

  def list_links(conn, %{"quest_id" => quest_id}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id) do
      links = Quests.links(conn.assigns.current_scope, quest_id)

      render(conn, :links,
        quest: quest,
        characters: links.characters,
        factions: links.factions,
        notes: links.notes,
        locations: links.locations,
        quests: links.quests
      )
    end
  end

  def delete_link(conn, %{
        "quest_id" => quest_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_quest_link(conn.assigns.current_scope, quest.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def update_link(
        conn,
        %{
          "quest_id" => quest_id,
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
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_quest_link(
             conn.assigns.current_scope,
             quest.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        quest_id: quest.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
    end
  end

  defp create_quest_link(scope, quest_id, :character, character_id, metadata_attrs) do
    Quests.link_character(scope, quest_id, character_id, metadata_attrs)
  end

  defp create_quest_link(scope, quest_id, :faction, faction_id, metadata_attrs) do
    Quests.link_faction(scope, quest_id, faction_id, metadata_attrs)
  end

  defp create_quest_link(scope, quest_id, :note, note_id, metadata_attrs) do
    Quests.link_note(scope, quest_id, note_id, metadata_attrs)
  end

  defp create_quest_link(scope, quest_id, :location, location_id, metadata_attrs) do
    Quests.link_location(scope, quest_id, location_id, metadata_attrs)
  end

  defp create_quest_link(scope, quest_id, :quest, other_quest_id, metadata_attrs) do
    Quests.link_quest(scope, quest_id, other_quest_id, metadata_attrs)
  end

  defp create_quest_link(_scope, _quest_id, entity_type, _entity_id, _metadata_attrs) do
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

  defp delete_quest_link(scope, quest_id, :quest, other_quest_id) do
    Quests.unlink_quest(scope, quest_id, other_quest_id)
  end

  defp delete_quest_link(_scope, _quest_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :quest, entity_type}}
  end

  defp update_quest_link(scope, quest_id, :note, note_id, metadata_attrs) do
    Quests.update_link_note(scope, quest_id, note_id, metadata_attrs)
  end

  defp update_quest_link(scope, quest_id, :character, character_id, metadata_attrs) do
    Quests.update_link_character(scope, quest_id, character_id, metadata_attrs)
  end

  defp update_quest_link(scope, quest_id, :faction, faction_id, metadata_attrs) do
    Quests.update_link_faction(scope, quest_id, faction_id, metadata_attrs)
  end

  defp update_quest_link(scope, quest_id, :location, location_id, metadata_attrs) do
    Quests.update_link_location(scope, quest_id, location_id, metadata_attrs)
  end

  defp update_quest_link(scope, quest_id, :quest, other_quest_id, metadata_attrs) do
    Quests.update_link_quest(scope, quest_id, other_quest_id, metadata_attrs)
  end

  defp update_quest_link(_scope, _quest_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :quest, entity_type}}
  end

  # Pinning endpoints

  def pin(conn, %{"quest_id" => quest_id}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id),
         {:ok, updated_quest} <- Quests.pin_quest(conn.assigns.current_scope, quest) do
      render(conn, :show, quest: updated_quest)
    end
  end

  def unpin(conn, %{"quest_id" => quest_id}) do
    with {:ok, quest} <- Quests.fetch_quest_for_game(conn.assigns.current_scope, quest_id),
         {:ok, updated_quest} <- Quests.unpin_quest(conn.assigns.current_scope, quest) do
      render(conn, :show, quest: updated_quest)
    end
  end
end
