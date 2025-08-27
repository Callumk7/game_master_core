defmodule GameMasterCoreWeb.LocationController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Locations
  alias GameMasterCore.Locations.Location

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    locations = Locations.list_locations(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  def create(conn, %{"location" => location_params}) do
    with {:ok, %Location{} = location} <- Locations.create_location(conn.assigns.current_scope, location_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/locations/#{location}")
      |> render(:show, location: location)
    end
  end

  def show(conn, %{"id" => id}) do
    location = Locations.get_location!(conn.assigns.current_scope, id)
    render(conn, :show, location: location)
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    location = Locations.get_location!(conn.assigns.current_scope, id)

    with {:ok, %Location{} = location} <- Locations.update_location(conn.assigns.current_scope, location, location_params) do
      render(conn, :show, location: location)
    end
  end

  def delete(conn, %{"id" => id}) do
    location = Locations.get_location!(conn.assigns.current_scope, id)

    with {:ok, %Location{}} <- Locations.delete_location(conn.assigns.current_scope, location) do
      send_resp(conn, :no_content, "")
    end
  end
end
