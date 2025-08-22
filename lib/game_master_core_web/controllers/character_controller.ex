defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Games

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, %{"game_id" => game_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    characters = Characters.list_characters_for_game(conn.assigns.current_scope, game)
    render(conn, :index, characters: characters)
  end

  def create(conn, %{"game_id" => game_id, "character" => character_params}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)

    with {:ok, %Character{} = character} <-
           Characters.create_character_for_game(
             conn.assigns.current_scope,
             game,
             character_params
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{game}/characters/#{character}")
      |> render(:show, character: character)
    end
  end

  def show(conn, %{"game_id" => game_id, "id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, id)
    render(conn, :show, character: character)
  end

  def update(conn, %{"game_id" => game_id, "id" => id, "character" => character_params}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, id)

    with {:ok, %Character{} = character} <-
           Characters.update_character(conn.assigns.current_scope, character, character_params) do
      render(conn, :show, character: character)
    end
  end

  def delete(conn, %{"game_id" => game_id, "id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, id)

    with {:ok, %Character{}} <- Characters.delete_character(conn.assigns.current_scope, character) do
      send_resp(conn, :no_content, "")
    end
  end
end
