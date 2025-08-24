defmodule GameMasterCoreWeb.FactionController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Factions
  alias GameMasterCore.Factions.Faction

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    factions = Factions.list_factions(conn.assigns.current_scope)
    render(conn, :index, factions: factions)
  end

  def create(conn, %{"faction" => faction_params}) do
    with {:ok, %Faction{} = faction} <- Factions.create_faction(conn.assigns.current_scope, faction_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{conn.assigns.current_scope.game}/factions/#{faction}")
      |> render(:show, faction: faction)
    end
  end

  def show(conn, %{"id" => id}) do
    faction = Factions.get_faction!(conn.assigns.current_scope, id)
    render(conn, :show, faction: faction)
  end

  def update(conn, %{"id" => id, "faction" => faction_params}) do
    faction = Factions.get_faction!(conn.assigns.current_scope, id)

    with {:ok, %Faction{} = faction} <- Factions.update_faction(conn.assigns.current_scope, faction, faction_params) do
      render(conn, :show, faction: faction)
    end
  end

  def delete(conn, %{"id" => id}) do
    faction = Factions.get_faction!(conn.assigns.current_scope, id)

    with {:ok, %Faction{}} <- Factions.delete_faction(conn.assigns.current_scope, faction) do
      send_resp(conn, :no_content, "")
    end
  end
end
