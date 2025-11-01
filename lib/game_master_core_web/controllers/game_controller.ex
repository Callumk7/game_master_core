defmodule GameMasterCoreWeb.GameController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Games
  alias GameMasterCore.Games.Game
  alias GameMasterCore.EntityTree
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

  def tree(conn, params) do
    # Parse and validate depth parameter
    depth =
      case Map.get(params, "depth") do
        nil ->
          3

        depth_str when is_binary(depth_str) ->
          case Integer.parse(depth_str) do
            {depth_int, ""} when depth_int >= 1 and depth_int <= 10 -> depth_int
            _ -> {:error, :invalid_depth}
          end

        _ ->
          {:error, :invalid_depth}
      end

    case depth do
      {:error, :invalid_depth} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid depth parameter. Must be an integer between 1 and 10."})

      depth_value ->
        # Get optional start entity parameters
        start_entity_type = Map.get(params, "start_entity_type")
        start_entity_id = Map.get(params, "start_entity_id")

        # Validate start entity parameters if provided
        case validate_start_entity_params(start_entity_type, start_entity_id) do
          {:error, message} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: message})

          :ok ->
            # Build entity tree
            opts = [
              depth: depth_value,
              start_entity_type: start_entity_type,
              start_entity_id: start_entity_id
            ]

            case EntityTree.build_entity_tree(conn.assigns.current_scope, opts) do
              {:ok, tree} ->
                render(conn, :tree, tree: tree)

              tree when is_map(tree) ->
                # Full game tree (not starting from specific entity)
                render(conn, :tree, tree: tree)

              {:error, :not_found} ->
                conn
                |> put_status(:not_found)
                |> json(%{error: "Starting entity not found"})

              {:error, :invalid_start_parameters} ->
                conn
                |> put_status(:bad_request)
                |> json(%{error: "Invalid start entity parameters"})

              {:error, reason} ->
                conn
                |> put_status(:internal_server_error)
                |> json(%{error: "Failed to build entity tree", reason: reason})
            end
        end
    end
  end

  # Private helpers

  defp validate_start_entity_params(nil, nil), do: :ok

  defp validate_start_entity_params(entity_type, entity_id)
       when is_binary(entity_type) and is_binary(entity_id) do
    valid_types = ["character", "faction", "location", "quest", "note"]

    if entity_type in valid_types do
      # Basic UUID format validation
      if String.match?(
           entity_id,
           ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
         ) do
        :ok
      else
        {:error, "Invalid entity_id format. Must be a valid UUID."}
      end
    else
      {:error, "Invalid entity_type. Must be one of: #{Enum.join(valid_types, ", ")}"}
    end
  end

  defp validate_start_entity_params(_, _) do
    {:error,
     "Both start_entity_type and start_entity_id must be provided together or both omitted"}
  end
end
