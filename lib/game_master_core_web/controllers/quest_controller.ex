defmodule GameMasterCoreWeb.QuestController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Quests
  alias GameMasterCore.Quests.Quest

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    quests = Quests.list_quests_for_game(conn.assigns.current_scope)
    render(conn, :index, quests: quests)
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
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, quest: quest)
  end

  def update(conn, %{"id" => id, "quest" => quest_params}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Quest{} = quest} <-
           Quests.update_quest(conn.assigns.current_scope, quest, quest_params) do
      render(conn, :show, quest: quest)
    end
  end

  def delete(conn, %{"id" => id}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Quest{}} <- Quests.delete_quest(conn.assigns.current_scope, quest) do
      send_resp(conn, :no_content, "")
    end
  end

  # Quest links
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

  def list_links(conn, %{"quest_id" => quest_id}) do
    quest = Quests.get_quest_for_game!(conn.assigns.current_scope, quest_id)

    links = Quests.links(conn.assigns.current_scope, quest.id)

    render(conn, :links, quest: quest, characters: links.characters, factions: links.factions, notes: links.notes, locations: links.locations)
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
