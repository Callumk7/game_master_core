defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Notes
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.CharacterSwagger

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
    with {:ok, character} <- Characters.fetch_character_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, character: character)
    end
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    with {:ok, character} <- Characters.fetch_character_for_game(conn.assigns.current_scope, id),
         {:ok, %Character{} = character} <-
           Characters.update_character(conn.assigns.current_scope, character, character_params) do
      render(conn, :show, character: character)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, character} <- Characters.fetch_character_for_game(conn.assigns.current_scope, id),
         {:ok, %Character{}} <- Characters.delete_character(conn.assigns.current_scope, character) do
      send_resp(conn, :no_content, "")
    end
  end

  def notes_tree(conn, params) do
    character_id = params["character_id"] || params["id"]

    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id) do
      notes_tree =
        Notes.list_character_notes_tree_for_game(conn.assigns.current_scope, character.id)

      render(conn, :notes_tree, character: character, notes_tree: notes_tree)
    end
  end

  def create_link(conn, %{"character_id" => character_id} = params) do
    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    # Extract metadata fields
    metadata_attrs = %{
      relationship_type: Map.get(params, "relationship_type"),
      description: Map.get(params, "description"),
      strength: Map.get(params, "strength"),
      is_active: Map.get(params, "is_active"),
      metadata: Map.get(params, "metadata")
    }

    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_character_link(
             conn.assigns.current_scope,
             character_id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
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
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id) do
      links = Characters.links(conn.assigns.current_scope, character_id)

      render(conn, :links,
        character: character,
        notes: links.notes,
        factions: links.factions,
        locations: links.locations,
        quests: links.quests,
        characters: links.characters
      )
    end
  end

  def delete_link(conn, %{
        "character_id" => character_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_character_link(conn.assigns.current_scope, character.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  # Private helpers for link management

  defp create_character_link(scope, character_id, :note, note_id, metadata_attrs) do
    Characters.link_note(scope, character_id, note_id, metadata_attrs)
  end

  defp create_character_link(scope, character_id, :faction, faction_id, metadata_attrs) do
    Characters.link_faction(scope, character_id, faction_id, metadata_attrs)
  end

  defp create_character_link(scope, character_id, :location, location_id, metadata_attrs) do
    Characters.link_location(scope, character_id, location_id, metadata_attrs)
  end

  defp create_character_link(scope, character_id, :quest, quest_id, metadata_attrs) do
    Characters.link_quest(scope, character_id, quest_id, metadata_attrs)
  end

  defp create_character_link(scope, character_id, :character, other_character_id, metadata_attrs) do
    Characters.link_character(scope, character_id, other_character_id, metadata_attrs)
  end

  defp create_character_link(_scope, _character_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end

  defp delete_character_link(scope, character_id, :note, note_id) do
    Characters.unlink_note(scope, character_id, note_id)
  end

  defp delete_character_link(scope, character_id, :faction, faction_id) do
    Characters.unlink_faction(scope, character_id, faction_id)
  end

  defp delete_character_link(scope, character_id, :location, location_id) do
    Characters.unlink_location(scope, character_id, location_id)
  end

  defp delete_character_link(scope, character_id, :quest, quest_id) do
    Characters.unlink_quest(scope, character_id, quest_id)
  end

  defp delete_character_link(scope, character_id, :character, other_character_id) do
    Characters.unlink_character(scope, character_id, other_character_id)
  end

  defp delete_character_link(_scope, _character_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end
end
