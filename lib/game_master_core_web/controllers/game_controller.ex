defmodule GameMasterCoreWeb.GameController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Games
  alias GameMasterCore.Games.Game
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  # CRUD operations - now much cleaner with centralized schemas
  swagger_path :index do
    get("/api/games")
    summary("List all games")
    description("Retrieve a list of all games accessible to the current user")
    operation_id("listGames")
    tag("GameMaster")
    produces("application/json")

    parameters do
    end

    response(200, "Success", Schema.ref(:GamesResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  def index(conn, _params) do
    games = Games.list_games(conn.assigns.current_scope)
    render(conn, :index, games: games)
  end

  swagger_path :create do
    post("/api/games")
    summary("Create a new game")
    description("Create a new game with the provided parameters")
    operation_id("createGame")
    tag("GameMaster")
    consumes("application/json")
    produces("application/json")

    parameters do
      body(:body, Schema.ref(:GameCreateRequest), "Game parameters", required: true)
    end

    response(201, "Created", Schema.ref(:GameResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def create(conn, %{"game" => game_params}) do
    with {:ok, %Game{} = game} <- Games.create_game(conn.assigns.current_scope, game_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{game}")
      |> render(:show, game: game)
    end
  end

  swagger_path :show do
    get("/api/games/{id}")
    summary("Get a game")
    description("Retrieve a specific game by its ID")
    operation_id("getGame")
    tag("GameMaster")
    produces("application/json")

    parameters do
      id(:path, :string, "Game ID", required: true, format: :uuid)
    end

    response(200, "Success", Schema.ref(:GameResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def show(conn, %{"id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, id)
    render(conn, :show, game: game)
  end

  swagger_path :update do
    put("/api/games/{id}")
    summary("Update a game")
    description("Update a specific game with the provided parameters")
    operation_id("updateGame")
    tag("GameMaster")
    consumes("application/json")
    produces("application/json")

    parameters do
      id(:path, :string, "Game ID", required: true, format: :uuid)
      body(:body, Schema.ref(:GameUpdateRequest), "Game parameters", required: true)
    end

    response(200, "Success", Schema.ref(:GameResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    game = Games.get_game!(conn.assigns.current_scope, id)

    with {:ok, %Game{} = game} <- Games.update_game(conn.assigns.current_scope, game, game_params) do
      render(conn, :show, game: game)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{id}")
    summary("Delete a game")
    description("Delete a specific game by its ID")
    operation_id("deleteGame")
    tag("GameMaster")

    parameters do
      id(:path, :string, "Game ID", required: true, format: :uuid)
    end

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def delete(conn, %{"id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, id)

    with {:ok, %Game{}} <- Games.delete_game(conn.assigns.current_scope, game) do
      send_resp(conn, :no_content, "")
    end
  end

  # Member operations - simplified
  swagger_path :add_member do
    post("/api/games/{game_id}/members")
    summary("Add a member to a game")
    description("Add a user as a member to the specified game")
    operation_id("addGameMember")
    tag("GameMaster")
    consumes("application/json")

    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      user_id(:formData, :integer, "User ID to add", required: true)
      role(:formData, :string, "Member role (default: 'member')")
    end

    response(201, "Created")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(403, "Forbidden", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def add_member(conn, %{"game_id" => game_id, "user_id" => user_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    role = Map.get(conn.params, "role", "member")

    case Games.add_member(conn.assigns.current_scope, game, user_id, role) do
      {:ok, _membership} ->
        send_resp(conn, :created, "")

      {:error, :unauthorized} ->
        send_resp(conn, :forbidden, "")
    end
  end

  swagger_path :remove_member do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/members/{user_id}")
    summary("Remove a member from a game")
    description("Remove a user from the specified game")
    operation_id("removeGameMember")
    tag("GameMaster")

    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      user_id(:path, :integer, "User ID to remove", required: true)
    end

    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def remove_member(conn, %{"game_id" => game_id, "user_id" => user_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)

    with {:ok, _} <- Games.remove_member(conn.assigns.current_scope, game, user_id) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :list_members do
    get("/api/games/{game_id}/members")
    summary("List game members")
    description("Retrieve a list of all members in the specified game")
    operation_id("listGameMembers")
    tag("GameMaster")
    produces("application/json")

    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
    end

    response(200, "Success", Schema.ref(:MembersResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_members(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    members = Games.list_members(conn.assigns.current_scope, game)
    render(conn, :members, members: members)
  end

  swagger_path :list_entities do
    get("/api/games/{game_id}/links")
    summary("List game entities")

    description(
      "Retrieve all entities (notes, characters, factions, locations, quests) for the specified game"
    )

    operation_id("listGameEntities")

    tag("GameMaster")
    produces("application/json")

    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
    end

    response(200, "Success", Schema.ref(:EntitiesResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  def list_entities(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    entities = Games.get_entities(conn.assigns.current_scope, game)

    render(conn, :entities, game: game, entities: entities)
  end
end
