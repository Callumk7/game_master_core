defmodule GameMasterCoreWeb.LocationController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Locations
  alias GameMasterCore.Locations.Location
  alias GameMasterCoreWeb.SwaggerDefinitions

  import GameMasterCoreWeb.Controllers.LinkHelpers

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.LocationSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def index(conn, _params) do
    locations = Locations.list_locations_for_game(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  def tree(conn, _params) do
    tree = Locations.list_locations_tree_for_game(conn.assigns.current_scope)
    render(conn, :tree, tree: tree)
  end

  def create(conn, %{"location" => location_params}) do
    with {:ok, %Location{} = location} <-
           Locations.create_location_for_game(conn.assigns.current_scope, location_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/games/#{conn.assigns.current_scope.game}/locations/#{location}"
      )
      |> render(:show, location: location)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id) do
      render(conn, :show, location: location)
    end
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id),
         {:ok, %Location{} = location} <-
           Locations.update_location(conn.assigns.current_scope, location, location_params) do
      render(conn, :show, location: location)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, location} <- Locations.fetch_location_for_game(conn.assigns.current_scope, id),
         {:ok, %Location{}} <- Locations.delete_location(conn.assigns.current_scope, location) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_link(conn, %{"location_id" => location_id} = params) do
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

    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           create_location_link(
             conn.assigns.current_scope,
             location.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Link created successfully",
        location_id: location.id,
        entity_type: entity_type,
        entity_id: entity_id
      })
    end
  end

  def list_links(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id) do
      try do
        links = Locations.links(conn.assigns.current_scope, location.id)

        render(conn, :links,
          location: location,
          notes: links.notes,
          factions: links.factions,
          characters: links.characters,
          quests: links.quests,
          locations: links.locations
        )
      rescue
        error in KeyError ->
          require Logger
          
          Logger.error("KeyError in location links for location_id: #{location_id}", %{
            location_id: location_id,
            game_id: conn.assigns.current_scope.game.id,
            error: inspect(error),
            location: %{
              id: location.id,
              name: location.name,
              game_id: location.game_id
            }
          })

          # Log detailed link information for debugging
          log_orphaned_link_details(conn.assigns.current_scope, location.id)

          # Return empty links structure to prevent 500 error
          render(conn, :links,
            location: location,
            notes: [],
            factions: [],
            characters: [],
            quests: [],
            locations: []
          )
      end
    end
  end

  def delete_link(conn, %{
        "location_id" => location_id,
        "entity_type" => entity_type,
        "entity_id" => entity_id
      }) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, _link} <-
           delete_location_link(conn.assigns.current_scope, location.id, entity_type, entity_id) do
      send_resp(conn, :no_content, "")
    end
  end

  def update_link(
        conn,
        %{
          "location_id" => location_id,
          "entity_type" => entity_type,
          "entity_id" => entity_id
        } = params
      ) do
    # Extract metadata fields
    metadata_attrs = %{
      relationship_type: Map.get(params, "relationship_type"),
      description: Map.get(params, "description"),
      strength: Map.get(params, "strength"),
      is_active: Map.get(params, "is_active"),
      metadata: Map.get(params, "metadata")
    }

    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, entity_id} <- validate_entity_id(entity_id),
         {:ok, updated_link} <-
           update_location_link(
             conn.assigns.current_scope,
             location.id,
             entity_type,
             entity_id,
             metadata_attrs
           ) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Link updated successfully",
        location_id: location.id,
        entity_type: entity_type,
        entity_id: entity_id,
        updated_at: updated_link.updated_at
      })
    end
  end

  # Private helpers for link management

  defp create_location_link(scope, location_id, :note, note_id, metadata_attrs) do
    Locations.link_note(scope, location_id, note_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :faction, faction_id, metadata_attrs) do
    Locations.link_faction(scope, location_id, faction_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :character, character_id, metadata_attrs) do
    Locations.link_character(scope, location_id, character_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :quest, quest_id, metadata_attrs) do
    Locations.link_quest(scope, location_id, quest_id, metadata_attrs)
  end

  defp create_location_link(scope, location_id, :location, other_location_id, metadata_attrs) do
    Locations.link_location(scope, location_id, other_location_id, metadata_attrs)
  end

  defp create_location_link(_scope, _location_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  defp delete_location_link(scope, location_id, :note, note_id) do
    Locations.unlink_note(scope, location_id, note_id)
  end

  defp delete_location_link(scope, location_id, :faction, faction_id) do
    Locations.unlink_faction(scope, location_id, faction_id)
  end

  defp delete_location_link(scope, location_id, :character, character_id) do
    Locations.unlink_character(scope, location_id, character_id)
  end

  defp delete_location_link(scope, location_id, :quest, quest_id) do
    Locations.unlink_quest(scope, location_id, quest_id)
  end

  defp delete_location_link(scope, location_id, :location, other_location_id) do
    Locations.unlink_location(scope, location_id, other_location_id)
  end

  defp delete_location_link(_scope, _location_id, entity_type, _entity_id) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  defp update_location_link(scope, location_id, :note, note_id, metadata_attrs) do
    Locations.update_link_note(scope, location_id, note_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :character, character_id, metadata_attrs) do
    Locations.update_link_character(scope, location_id, character_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :faction, faction_id, metadata_attrs) do
    Locations.update_link_faction(scope, location_id, faction_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :quest, quest_id, metadata_attrs) do
    Locations.update_link_quest(scope, location_id, quest_id, metadata_attrs)
  end

  defp update_location_link(scope, location_id, :location, other_location_id, metadata_attrs) do
    Locations.update_link_location(scope, location_id, other_location_id, metadata_attrs)
  end

  defp update_location_link(_scope, _location_id, entity_type, _entity_id, _metadata_attrs) do
    {:error, {:unsupported_link_type, :location, entity_type}}
  end

  # Pinning endpoints

  def pin(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, updated_location} <- Locations.pin_location(conn.assigns.current_scope, location) do
      render(conn, :show, location: updated_location)
    end
  end

  def unpin(conn, %{"location_id" => location_id}) do
    with {:ok, location} <-
           Locations.fetch_location_for_game(conn.assigns.current_scope, location_id),
         {:ok, updated_location} <- Locations.unpin_location(conn.assigns.current_scope, location) do
      render(conn, :show, location: updated_location)
    end
  end

  # Private helper to log detailed orphaned link information
  defp log_orphaned_link_details(_scope, location_id) do
    require Logger
    alias GameMasterCore.Repo
    import Ecto.Query

    # Check for orphaned location_notes
    orphaned_notes = from(ln in "location_notes",
      left_join: n in "notes", on: ln.note_id == n.id,
      where: ln.location_id == ^location_id and is_nil(n.id),
      select: %{link_id: ln.id, note_id: ln.note_id, relationship_type: ln.relationship_type}
    ) |> Repo.all()

    if orphaned_notes != [] do
      Logger.error("Found orphaned location_notes for location #{location_id}: #{inspect(orphaned_notes)}")
    end

    # Check for orphaned character_locations
    orphaned_characters = from(cl in "character_locations",
      left_join: c in "characters", on: cl.character_id == c.id,
      where: cl.location_id == ^location_id and is_nil(c.id),
      select: %{link_id: cl.id, character_id: cl.character_id, relationship_type: cl.relationship_type}
    ) |> Repo.all()

    if orphaned_characters != [] do
      Logger.error("Found orphaned character_locations for location #{location_id}: #{inspect(orphaned_characters)}")
    end

    # Check for orphaned faction_locations
    orphaned_factions = from(fl in "faction_locations",
      left_join: f in "factions", on: fl.faction_id == f.id,
      where: fl.location_id == ^location_id and is_nil(f.id),
      select: %{link_id: fl.id, faction_id: fl.faction_id, relationship_type: fl.relationship_type}
    ) |> Repo.all()

    if orphaned_factions != [] do
      Logger.error("Found orphaned faction_locations for location #{location_id}: #{inspect(orphaned_factions)}")
    end

    # Check for orphaned quests_locations
    orphaned_quests = from(ql in "quests_locations",
      left_join: q in "quests", on: ql.quest_id == q.id,
      where: ql.location_id == ^location_id and is_nil(q.id),
      select: %{link_id: ql.id, quest_id: ql.quest_id, relationship_type: ql.relationship_type}
    ) |> Repo.all()

    if orphaned_quests != [] do
      Logger.error("Found orphaned quests_locations for location #{location_id}: #{inspect(orphaned_quests)}")
    end

    # Check for orphaned location_locations (self-references)
    orphaned_locations = from(ll in "location_locations",
      left_join: l1 in "locations", on: ll.location_id_1 == l1.id,
      left_join: l2 in "locations", on: ll.location_id_2 == l2.id,
      where: (ll.location_id_1 == ^location_id and is_nil(l1.id)) or 
             (ll.location_id_2 == ^location_id and is_nil(l2.id)),
      select: %{link_id: ll.id, location_id_1: ll.location_id_1, location_id_2: ll.location_id_2, relationship_type: ll.relationship_type}
    ) |> Repo.all()

    if orphaned_locations != [] do
      Logger.error("Found orphaned location_locations for location #{location_id}: #{inspect(orphaned_locations)}")
    end

    Logger.info("Completed orphaned link check for location #{location_id}")
  end
end
