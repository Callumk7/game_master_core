defmodule GameMasterCoreWeb.Controllers.EntityController do
  @moduledoc """
  Shared behavior for entity CRUD controllers.

  Provides generic implementations for:
  - Standard CRUD (index, show, create, update, delete)
  - Link management (create_link, list_links, update_link, delete_link)
  - Pinning (pin, unpin)

  ## Usage

      defmodule GameMasterCoreWeb.CharacterController do
        use GameMasterCoreWeb, :controller
        use GameMasterCoreWeb.Controllers.EntityController,
          context: GameMasterCore.Characters,
          schema: GameMasterCore.Characters.Character,
          entity_name: :character,
          entity_type: "character"

        # Only character-specific actions here
        def get_primary_faction(conn, %{"character_id" => id}) do
          # character-specific logic
        end
      end
  """

  defmacro __using__(opts) do
    context_module = Keyword.fetch!(opts, :context)
    schema_module = Keyword.fetch!(opts, :schema)
    entity_name = Keyword.fetch!(opts, :entity_name)
    entity_type = Keyword.fetch!(opts, :entity_type)

    # Convert entity_name atom to string variants for function names
    entity_str = Atom.to_string(entity_name)
    # Simple pluralization
    entities_str = "#{entity_str}s"

    # Generate function names based on context conventions
    list_fn = String.to_atom("list_#{entities_str}_for_game")
    fetch_fn = String.to_atom("fetch_#{entity_str}_for_game")
    create_fn = String.to_atom("create_#{entity_str}_for_game")
    update_fn = String.to_atom("update_#{entity_str}")
    delete_fn = String.to_atom("delete_#{entity_str}")

    # Bodyguard action atoms
    update_action = String.to_atom("update_#{entity_str}")
    delete_action = String.to_atom("delete_#{entity_str}")

    quote do
      alias unquote(context_module)
      alias unquote(schema_module)
      import Ecto.Changeset

      action_fallback GameMasterCoreWeb.FallbackController

      # ============================================================================
      # STANDARD CRUD OPERATIONS
      # ============================================================================

      @doc """
      List all entities for the current game.
      GET /api/games/:game_id/#{unquote(entities_str)}
      """
      def index(conn, _params) do
        scope = conn.assigns.current_scope
        entities = unquote(context_module).unquote(list_fn)(scope)
        # Use String.to_atom to create the plural key dynamically
        key = String.to_atom(unquote(entities_str))
        render(conn, :index, [{key, entities}])
      end

      @doc """
      Show a specific entity.
      GET /api/games/:game_id/#{unquote(entities_str)}/:id
      """
      def show(conn, %{"id" => id}) do
        scope = conn.assigns.current_scope

        with {:ok, entity} <- unquote(context_module).unquote(fetch_fn)(scope, id) do
          render(conn, :show, [{unquote(entity_name), entity}])
        end
      end

      @doc """
      Create a new entity.
      POST /api/games/:game_id/#{unquote(entities_str)}
      """
      def create(conn, %{unquote(entity_type) => entity_params}) do
        scope = conn.assigns.current_scope

        with {:ok, entity} <- unquote(context_module).unquote(create_fn)(scope, entity_params) do
          conn
          |> put_status(:created)
          |> put_resp_header(
            "location",
            "/api/games/#{scope.game.id}/#{unquote(entities_str)}/#{entity.id}"
          )
          |> render(:show, [{unquote(entity_name), entity}])
        end
      end

      @doc """
      Update an existing entity.
      PUT/PATCH /api/games/:game_id/#{unquote(entities_str)}/:id
      """
      def update(conn, %{"id" => id, unquote(entity_type) => entity_params}) do
        scope = conn.assigns.current_scope

        with {:ok, entity} <- unquote(context_module).unquote(fetch_fn)(scope, id),
             :ok <-
               Bodyguard.permit(
                 unquote(context_module),
                 unquote(update_action),
                 scope.user,
                 entity
               ),
             {:ok, updated_entity} <-
               unquote(context_module).unquote(update_fn)(scope, entity, entity_params) do
          render(conn, :show, [{unquote(entity_name), updated_entity}])
        end
      end

      @doc """
      Delete an entity.
      DELETE /api/games/:game_id/#{unquote(entities_str)}/:id
      """
      def delete(conn, %{"id" => id}) do
        scope = conn.assigns.current_scope

        with {:ok, entity} <- unquote(context_module).unquote(fetch_fn)(scope, id),
             :ok <-
               Bodyguard.permit(
                 unquote(context_module),
                 unquote(delete_action),
                 scope.user,
                 entity
               ),
             {:ok, _deleted_entity} <- unquote(context_module).unquote(delete_fn)(scope, entity) do
          send_resp(conn, :no_content, "")
        end
      end

      # ============================================================================
      # OVERRIDABLE FUNCTIONS
      # ============================================================================

      # Allow individual functions to be overridden
      defoverridable index: 2,
                     show: 2,
                     create: 2,
                     update: 2,
                     delete: 2
    end
  end
end
