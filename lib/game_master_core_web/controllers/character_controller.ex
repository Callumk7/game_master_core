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

  # Character Links

  def create_link(conn, %{"game_id" => game_id, "character_id" => character_id} = params) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, character_id)

    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_character_link(conn.assigns.current_scope, character.id, entity_type, entity_id) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        character_id: character.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  def list_links(conn, %{"game_id" => game_id, "character_id" => character_id}) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, character_id)

    links = Characters.linked_notes(conn.assigns.current_scope, character.id)

    render(conn, :links, character: character, notes: links)
  end

  def delete_link(conn, %{
        "game_id" => game_id,
        "character_id" => character_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    game = Games.get_game!(conn.assigns.current_scope, game_id)
    character = Characters.get_character_for_game!(conn.assigns.current_scope, game, character_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_character_link(conn.assigns.current_scope, character.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp validate_entity_type(nil), do: {:error, :missing_entity_type}
  defp validate_entity_type("note"), do: {:ok, :note}
  defp validate_entity_type("faction"), do: {:ok, :faction}
  defp validate_entity_type("item"), do: {:ok, :item}
  defp validate_entity_type("location"), do: {:ok, :location}
  defp validate_entity_type("quest"), do: {:ok, :quest}
  defp validate_entity_type(_), do: {:error, :invalid_entity_type}

  defp validate_entity_id(nil), do: {:error, :missing_entity_id}

  defp validate_entity_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {integer_id, ""} -> {:ok, integer_id}
      _ -> {:error, :invalid_entity_id}
    end
  end

  defp validate_entity_id(id) when is_integer(id), do: {:ok, id}
  defp validate_entity_id(_), do: {:error, :invalid_entity_id}

  defp create_character_link(scope, character_id, :note, note_id) do
    Characters.link_note(scope, character_id, note_id)
  end

  defp create_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, entity_type}}
  end

  defp delete_character_link(scope, character_id, :note, note_id) do
    Characters.unlink_note(scope, character_id, note_id)
  end

  defp delete_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, entity_type}}
  end
end
