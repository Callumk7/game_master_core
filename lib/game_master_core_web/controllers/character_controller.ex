defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character

  import GameMasterCoreWeb.Controllers.LinkHelpers

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    characters = Characters.list_characters_for_game(conn.assigns.current_scope)
    render(conn, :index, characters: characters)
  end

  def create(conn, %{"character" => character_params}) do
    with {:ok, %Character{} = character} <-
           Characters.create_character_for_game(
             conn.assigns.current_scope,
             character_params
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/characters/#{character}"
      )
      |> render(:show, character: character)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, character: character)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Character{} = character} <-
           Characters.update_character(conn.assigns.current_scope, character, character_params) do
      render(conn, :show, character: character)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)

    with {:ok, %Character{}} <- Characters.delete_character(conn.assigns.current_scope, character) do
      send_resp(conn, :no_content, "")
    end
  end

  # Character Links

  def create_link(conn, %{"character_id" => character_id} = params) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

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

  def list_links(conn, %{"character_id" => character_id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

    links = Characters.links(conn.assigns.current_scope, character.id)

    render(conn, :links, character: character, notes: links.notes, factions: links.factions)
  end

  def delete_link(conn, %{
        "character_id" => character_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, character_id)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_character_link(conn.assigns.current_scope, character.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_character_link(scope, character_id, :note, note_id) do
    Characters.link_note(scope, character_id, note_id)
  end

  defp create_character_link(scope, character_id, :faction, faction_id) do
    Characters.link_faction(scope, character_id, faction_id)
  end

  defp create_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end

  defp delete_character_link(scope, character_id, :note, note_id) do
    Characters.unlink_note(scope, character_id, note_id)
  end

  defp delete_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end
end
