defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  # ============================================================================
  # USE THE ENTITY CONTROLLER MACRO
  # This provides: index, show, create, update, delete with proper authorization
  # ============================================================================
  use GameMasterCoreWeb.Controllers.EntityController,
    context: GameMasterCore.Characters,
    schema: GameMasterCore.Characters.Character,
    entity_name: :character,
    entity_type: "character"

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.CharacterSwagger

  # Note: action_fallback is already set by EntityController macro

  # ============================================================================
  # OVERRIDE CREATE TO HANDLE LINKS IN PARAMS
  # ============================================================================
  # Characters support creating with links in a single request

  def create(conn, %{"character" => character_params} = params) do
    links = Map.get(params, "links", [])

    creation_result =
      if Enum.empty?(links) do
        # Existing path - backward compatible
        Characters.create_character_for_game(conn.assigns.current_scope, character_params)
      else
        # New path - create character with links
        Characters.create_character_with_links(
          conn.assigns.current_scope,
          character_params,
          links
        )
      end

    with {:ok, %Character{} = character} <- creation_result do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/characters/#{character}"
      )
      |> render(:show, character: character)
    end
  end

  # ============================================================================
  # CHARACTER-SPECIFIC: PRIMARY FACTION MANAGEMENT
  # ============================================================================

  @doc """
  Get the primary faction for a character.
  GET /api/games/:game_id/characters/:character_id/primary-faction
  """
  def get_primary_faction(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id) do
      case Characters.get_primary_faction(conn.assigns.current_scope, character) do
        {:ok, primary_faction_data} ->
          render(conn, :primary_faction, primary_faction_data: primary_faction_data)

        {:error, :no_primary_faction} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "No primary faction set for this character"})
      end
    end
  end

  @doc """
  Set the primary faction for a character.
  PUT /api/games/:game_id/characters/:character_id/primary-faction
  """
  def set_primary_faction(conn, %{
        "character_id" => character_id,
        "faction_id" => faction_id,
        "role" => role
      }) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, updated_character} <-
           Characters.set_primary_faction(conn.assigns.current_scope, character, faction_id, role) do
      render(conn, :show, character: updated_character)
    end
  end

  @doc """
  Remove the primary faction from a character.
  DELETE /api/games/:game_id/characters/:character_id/primary-faction
  """
  def remove_primary_faction(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, updated_character} <-
           Characters.remove_primary_faction(conn.assigns.current_scope, character) do
      render(conn, :show, character: updated_character)
    end
  end

  # ============================================================================
  # PINNING OPERATIONS
  # ============================================================================
  # Note: Pin/unpin use entity-specific parameter names (:character_id) in nested routes

  def pin(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, updated_character} <-
           Characters.pin_character(conn.assigns.current_scope, character) do
      render(conn, :show, character: updated_character)
    end
  end

  def unpin(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, updated_character} <-
           Characters.unpin_character(conn.assigns.current_scope, character) do
      render(conn, :show, character: updated_character)
    end
  end

  # ============================================================================
  # LINK MANAGEMENT WITH CHARACTER-SPECIFIC METADATA
  # ============================================================================
  # Characters have extensive link metadata (relationship_type, faction_role, etc.)

  def create_link(conn, %{"character_id" => character_id} = params) do
    entity_type = Map.get(params, "entity_type")
    entity_id = Map.get(params, "entity_id")

    # Extract metadata fields specific to character links
    metadata_attrs =
      %{
        relationship_type: Map.get(params, "relationship_type"),
        description: Map.get(params, "description"),
        strength: Map.get(params, "strength"),
        is_active: Map.get(params, "is_active"),
        is_current_location: Map.get(params, "is_current_location"),
        is_primary: Map.get(params, "is_primary"),
        faction_role: Map.get(params, "faction_role"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

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

  def update_link(
        conn,
        %{
          "character_id" => character_id,
          "entity_type" => entity_type,
          "entity_id" => entity_id
        } = params
      ) do
    # Extract metadata fields, excluding nils to preserve existing values
    metadata_attrs =
      %{
        relationship_type: Map.get(params, "relationship_type"),
        description: Map.get(params, "description"),
        strength: Map.get(params, "strength"),
        is_active: Map.get(params, "is_active"),
        is_current_location: Map.get(params, "is_current_location"),
        is_primary: Map.get(params, "is_primary"),
        faction_role: Map.get(params, "faction_role"),
        metadata: Map.get(params, "metadata")
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.current_scope, character_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_character_link(
             conn.assigns.current_scope,
             character.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        character_id: character.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
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

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS FOR LINK DISPATCH
  # ============================================================================
  # These dispatch to the appropriate Characters context functions based on entity type

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

  defp update_character_link(scope, character_id, :note, note_id, metadata_attrs) do
    Characters.update_link_note(scope, character_id, note_id, metadata_attrs)
  end

  defp update_character_link(scope, character_id, :faction, faction_id, metadata_attrs) do
    Characters.update_link_faction(scope, character_id, faction_id, metadata_attrs)
  end

  defp update_character_link(scope, character_id, :location, location_id, metadata_attrs) do
    Characters.update_link_location(scope, character_id, location_id, metadata_attrs)
  end

  defp update_character_link(scope, character_id, :quest, quest_id, metadata_attrs) do
    Characters.update_link_quest(scope, character_id, quest_id, metadata_attrs)
  end

  defp update_character_link(scope, character_id, :character, other_character_id, metadata_attrs) do
    Characters.update_link_character(scope, character_id, other_character_id, metadata_attrs)
  end

  defp update_character_link(_scope, _character_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :character, entity_type}}
  end
end
