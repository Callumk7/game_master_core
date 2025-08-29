defmodule GameMasterCoreWeb.QuestController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Quests
  alias GameMasterCore.Quests.Quest

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    quests = Quests.list_quests(conn.assigns.current_scope)
    render(conn, :index, quests: quests)
  end

  def create(conn, %{"quest" => quest_params}) do
    with {:ok, %Quest{} = quest} <- Quests.create_quest(conn.assigns.current_scope, quest_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{conn.assigns.current_scope.game}/quests/#{quest}")
      |> render(:show, quest: quest)
    end
  end

  def show(conn, %{"id" => id}) do
    quest = Quests.get_quest!(conn.assigns.current_scope, id)
    render(conn, :show, quest: quest)
  end

  def update(conn, %{"id" => id, "quest" => quest_params}) do
    quest = Quests.get_quest!(conn.assigns.current_scope, id)

    with {:ok, %Quest{} = quest} <- Quests.update_quest(conn.assigns.current_scope, quest, quest_params) do
      render(conn, :show, quest: quest)
    end
  end

  def delete(conn, %{"id" => id}) do
    quest = Quests.get_quest!(conn.assigns.current_scope, id)

    with {:ok, %Quest{}} <- Quests.delete_quest(conn.assigns.current_scope, quest) do
      send_resp(conn, :no_content, "")
    end
  end
end
