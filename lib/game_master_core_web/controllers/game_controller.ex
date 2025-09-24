defmodule GameMasterCoreWeb.GameController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Games
  alias GameMasterCore.Games.Game
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.GameSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    games = Games.list_games(conn.assigns.current_scope)
    render(conn, :index, games: games)
  end

  def create(conn, %{"game" => game_params}) do
    with {:ok, %Game{} = game} <- Games.create_game(conn.assigns.current_scope, game_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{game}")
      |> render(:show, game: game)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id) do
      render(conn, :show, game: game)
    end
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id),
         {:ok, %Game{} = game} <- Games.update_game(conn.assigns.current_scope, game, game_params) do
      render(conn, :show, game: game)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id),
         {:ok, %Game{}} <- Games.delete_game(conn.assigns.current_scope, game) do
      send_resp(conn, :no_content, "")
    end
  end

  def add_member(conn, %{"game_id" => game_id, "user_id" => user_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      role = Map.get(conn.params, "role", "member")

      case Games.add_member(conn.assigns.current_scope, game, user_id, role) do
        {:ok, _membership} ->
          send_resp(conn, :created, "")

        {:error, :unauthorized} ->
          send_resp(conn, :forbidden, "")
      end
    end
  end

  def remove_member(conn, %{"game_id" => game_id, "user_id" => user_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id),
         {:ok, _} <- Games.remove_member(conn.assigns.current_scope, game, user_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def list_members(conn, %{"game_id" => game_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      members = Games.list_members(conn.assigns.current_scope, game)
      render(conn, :members, members: members)
    end
  end

  def list_entities(conn, %{"game_id" => game_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      entities = Games.get_entities(conn.assigns.current_scope, game)

      render(conn, :entities, game: game, entities: entities)
    end
  end
end
