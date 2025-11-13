defmodule GameMasterCoreWeb.ObjectiveController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Objectives
  alias GameMasterCore.Quests.Objective
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.ObjectiveSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, %{"quest_id" => quest_id}) do
    with {:ok, objectives} <-
           Objectives.list_objectives_for_quest(conn.assigns.current_scope, quest_id) do
      render(conn, :index, objectives: objectives)
    end
  end

  def game_objectives(conn, _params) do
    objectives = Objectives.list_objectives_for_game(conn.assigns.current_scope)
    render(conn, :index, objectives: objectives)
  end

  def create(conn, %{"quest_id" => quest_id, "objective" => objective_params}) do
    with {:ok, %Objective{} = objective} <-
           Objectives.create_objective_for_quest(
             conn.assigns.current_scope,
             quest_id,
             objective_params
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/quests/#{quest_id}/objectives/#{objective}"
      )
      |> render(:show, objective: objective)
    end
  end

  def show(conn, %{"quest_id" => quest_id, "id" => id}) do
    with {:ok, objective} <-
           Objectives.fetch_objective_for_quest(conn.assigns.current_scope, quest_id, id) do
      render(conn, :show, objective: objective)
    end
  end

  def update(conn, %{"quest_id" => quest_id, "id" => id, "objective" => objective_params}) do
    with {:ok, objective} <-
           Objectives.fetch_objective_for_quest(conn.assigns.current_scope, quest_id, id),
         :ok <-
           Bodyguard.permit(Objectives, :update_objective, conn.assigns.current_scope.user, objective),
         {:ok, %Objective{} = objective} <-
           Objectives.update_objective_for_quest(
             conn.assigns.current_scope,
             quest_id,
             id,
             objective_params
           ) do
      render(conn, :show, objective: objective)
    end
  end

  def delete(conn, %{"quest_id" => quest_id, "id" => id}) do
    with {:ok, objective} <-
           Objectives.fetch_objective_for_quest(conn.assigns.current_scope, quest_id, id),
         :ok <-
           Bodyguard.permit(Objectives, :delete_objective, conn.assigns.current_scope.user, objective),
         {:ok, %Objective{}} <-
           Objectives.delete_objective_for_quest(conn.assigns.current_scope, quest_id, id) do
      send_resp(conn, :no_content, "")
    end
  end

  def complete(conn, %{"quest_id" => quest_id, "objective_id" => objective_id}) do
    with {:ok, %Objective{} = objective} <-
           Objectives.complete_objective(conn.assigns.current_scope, quest_id, objective_id) do
      render(conn, :show, objective: objective)
    end
  end

  def uncomplete(conn, %{"quest_id" => quest_id, "objective_id" => objective_id}) do
    with {:ok, %Objective{} = objective} <-
           Objectives.uncomplete_objective(conn.assigns.current_scope, quest_id, objective_id) do
      render(conn, :show, objective: objective)
    end
  end
end
