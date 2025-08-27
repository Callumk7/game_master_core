defmodule GameMasterCoreWeb.FactionController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Factions
  alias GameMasterCore.Factions.Faction

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    factions = Factions.list_factions_for_game(conn.assigns.current_scope)
    render(conn, :index, factions: factions)
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
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, faction: faction)
  end

  def update(conn, %{"id" => id, "faction" => faction_params}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Faction{} = faction} <-
           Factions.update_faction(conn.assigns.current_scope, faction, faction_params) do
      render(conn, :show, faction: faction)
    end
  end

  def delete(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Faction{}} <- Factions.delete_faction(conn.assigns.current_scope, faction) do
      send_resp(conn, :no_content, "")
    end
  end

  # Faction Links

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

  def list_links(conn, %{"faction_id" => faction_id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, faction_id)

    notes = Factions.linked_notes(conn.assigns.current_scope, faction_id)
    characters = Factions.linked_characters(conn.assigns.current_scope, faction_id)

    render(conn, :links, faction: faction, notes: notes, characters: characters)
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

  defp create_faction_link(_scope, _faction_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end

  defp delete_faction_link(scope, faction_id, :note, note_id) do
    Factions.unlink_note(scope, faction_id, note_id)
  end

  defp delete_faction_link(scope, faction_id, :character, character_id) do
    Factions.unlink_character(scope, faction_id, character_id)
  end

  defp delete_faction_link(_scope, _faction_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :faction, entity_type}}
  end
end
