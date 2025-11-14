# EntityController Macro Usage Example

This document shows how the `EntityController` macro would be used to reduce duplication.

## Before: CharacterController (338 lines)

The current CharacterController has all CRUD operations written out explicitly.

## After: CharacterController Using Macro (~150 lines)

```elixir
defmodule GameMasterCoreWeb.CharacterController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  # ============================================================================
  # USE THE ENTITY CONTROLLER MACRO
  # This single declaration provides: index, show, create, update, delete, pin, unpin, and basic link management
  # ============================================================================
  use GameMasterCoreWeb.Controllers.EntityController,
    context: GameMasterCore.Characters,
    schema: GameMasterCore.Characters.Character,
    entity_name: :character,
    entity_type: "character"

  alias GameMasterCore.Characters
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.CharacterSwagger

  # ============================================================================
  # CHARACTER-SPECIFIC OVERRIDES
  # ============================================================================
  # If characters need special handling (like link creation with metadata),
  # we can override the macro-provided functions

  # Override create if needed for "create with links" feature
  def create(conn, %{"character" => character_params} = params) do
    links = Map.get(params, "links", [])
    scope = conn.assigns.scope

    creation_result =
      if Enum.empty?(links) do
        Characters.create_character_for_game(scope, character_params)
      else
        Characters.create_character_with_links(scope, character_params, links)
      end

    with {:ok, character} <- creation_result do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/games/#{scope.game}/characters/#{character}")
      |> render(:show, character: character)
    end
  end

  # ============================================================================
  # CHARACTER-SPECIFIC ACTIONS
  # ============================================================================
  # These are unique to characters and not provided by the macro

  def get_primary_faction(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.scope, character_id) do
      case Characters.get_primary_faction(conn.assigns.scope, character) do
        {:ok, primary_faction_data} ->
          render(conn, :primary_faction, primary_faction_data: primary_faction_data)

        {:error, :no_primary_faction} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "No primary faction set for this character"})
      end
    end
  end

  def set_primary_faction(conn, %{
        "character_id" => character_id,
        "faction_id" => faction_id,
        "role" => role
      }) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.scope, character_id),
         {:ok, updated_character} <-
           Characters.set_primary_faction(conn.assigns.scope, character, faction_id, role) do
      render(conn, :show, character: updated_character)
    end
  end

  def remove_primary_faction(conn, %{"character_id" => character_id}) do
    with {:ok, character} <-
           Characters.fetch_character_for_game(conn.assigns.scope, character_id),
         {:ok, updated_character} <-
           Characters.remove_primary_faction(conn.assigns.scope, character) do
      render(conn, :show, character: updated_character)
    end
  end
end
```

## Simple Example: QuestController

For entities without special features, the controller becomes extremely minimal:

```elixir
defmodule GameMasterCoreWeb.QuestController do
  use GameMasterCoreWeb, :controller

  # This provides ALL functionality: CRUD + links + pinning
  use GameMasterCoreWeb.Controllers.EntityController,
    context: GameMasterCore.Quests,
    schema: GameMasterCore.Quests.Quest,
    entity_name: :quest,
    entity_type: "quest"

  # That's it! No additional code needed unless you have quest-specific actions
end
```

## What Gets Generated

When you `use EntityController`, it generates:

### Standard CRUD:
- `index/2` - GET /api/games/:game_id/quests
- `show/2` - GET /api/games/:game_id/quests/:id
- `create/2` - POST /api/games/:game_id/quests
- `update/2` - PUT/PATCH /api/games/:game_id/quests/:id
- `delete/2` - DELETE /api/games/:game_id/quests/:id

### Pinning:
- `pin/2` - PUT /api/games/:game_id/quests/:id/pin
- `unpin/2` - PUT /api/games/:game_id/quests/:id/unpin

### Link Management:
- `create_link/2` - POST /api/games/:game_id/quests/:quest_id/links
- `list_links/2` - GET /api/games/:game_id/quests/:quest_id/links
- `update_link/2` - PATCH /api/games/:game_id/quests/:quest_id/links/:link_id
- `delete_link/2` - DELETE /api/games/:game_id/quests/:quest_id/links/:link_id

All with proper:
- ✅ Bodyguard authorization checks on update/delete
- ✅ Scope-based access control
- ✅ Error handling via FallbackController
- ✅ Proper HTTP status codes
- ✅ RESTful conventions

## Code Reduction

| Controller | Before (lines) | After (lines) | Reduction |
|------------|----------------|---------------|-----------|
| CharacterController | 338 | ~150 | 56% |
| FactionController | 292 | ~50 | 83% |
| LocationController | 295 | ~50 | 83% |
| NoteController | 266 | ~50 | 81% |
| QuestController | 280 | ~50 | 82% |
| **Total** | **1,471** | **~350** | **76%** |
