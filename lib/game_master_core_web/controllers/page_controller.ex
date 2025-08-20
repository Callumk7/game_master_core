defmodule GameMasterCoreWeb.PageController do
  use GameMasterCoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
