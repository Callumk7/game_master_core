defmodule GameMasterCoreWeb.Admin.FactionController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games
  alias GameMasterCore.Factions
  alias GameMasterCore.Factions.Faction

  plug :load_game

  def index(conn, _params) do
    factions = Factions.list_factions_for_game(conn.assigns.current_scope)
    render(conn, :index, factions: factions)
  end

  def new(conn, _params) do
    changeset =
      Factions.change_faction(conn.assigns.current_scope, %Faction{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"faction" => faction_params}) do
    case Factions.create_faction_for_game(conn.assigns.current_scope, faction_params) do
      {:ok, faction} ->
        conn
        |> put_flash(:info, "Faction created successfully.")
        |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/factions/#{faction}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, faction: faction)
  end

  def edit(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)
    changeset = Factions.change_faction(conn.assigns.current_scope, faction)
    render(conn, :edit, faction: faction, changeset: changeset)
  end

  def update(conn, %{"id" => id, "faction" => faction_params}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)

    case Factions.update_faction(conn.assigns.current_scope, faction, faction_params) do
      {:ok, faction} ->
        conn
        |> put_flash(:info, "Faction updated successfully.")
        |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/factions/#{faction}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, faction: faction, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    faction = Factions.get_faction_for_game!(conn.assigns.current_scope, id)
    {:ok, _faction} = Factions.delete_faction(conn.assigns.current_scope, faction)

    conn
    |> put_flash(:info, "Faction deleted successfully.")
    |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/factions")
  end

  defp load_game(conn, _opts) do
    current_scope = conn.assigns.current_scope

    if game_id = conn.params["game_id"] do
      game = Games.get_game!(current_scope, game_id)

      conn
      |> assign(:game, game)
      |> assign(:current_scope, Scope.put_game(current_scope, game))
    else
      conn
    end
  end
end