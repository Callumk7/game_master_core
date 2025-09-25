defmodule GameMasterCoreWeb.PinnedController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Characters
  alias GameMasterCore.Notes
  alias GameMasterCore.Factions
  alias GameMasterCore.Locations
  alias GameMasterCore.Quests
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.PinnedSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  @doc """
  Lists all pinned entities for a specific game.
  Returns pinned characters, notes, factions, locations, and quests.
  """
  def index(conn, _params) do
    scope = conn.assigns.current_scope

    pinned_characters = Characters.list_pinned_characters_for_game(scope)
    pinned_notes = Notes.list_pinned_notes_for_game(scope)
    pinned_factions = Factions.list_pinned_factions_for_game(scope)
    pinned_locations = Locations.list_pinned_locations_for_game(scope)
    pinned_quests = Quests.list_pinned_quests_for_game(scope)

    render(conn, :index,
      game_id: scope.game.id,
      characters: pinned_characters,
      notes: pinned_notes,
      factions: pinned_factions,
      locations: pinned_locations,
      quests: pinned_quests
    )
  end
end
