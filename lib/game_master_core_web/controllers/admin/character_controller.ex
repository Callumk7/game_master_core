defmodule GameMasterCoreWeb.Admin.CharacterController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games
  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.Character

  plug :load_game

  def index(conn, _params) do
    characters = Characters.list_characters_for_game(conn.assigns.current_scope)
    render(conn, :index, characters: characters)
  end

  def new(conn, _params) do
    changeset =
      Characters.change_character(conn.assigns.current_scope, %Character{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"character" => character_params}) do
    case Characters.create_character_for_game(conn.assigns.current_scope, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:info, "Character created successfully.")
        |> redirect(
          to: ~p"/admin/games/#{conn.assigns.current_scope.game}/characters/#{character}"
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)
    render(conn, :show, character: character)
  end

  def edit(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)
    changeset = Characters.change_character(conn.assigns.current_scope, character)
    render(conn, :edit, character: character, changeset: changeset)
  end

  def update(conn, %{"id" => id, "character" => character_params}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)

    case Characters.update_character(conn.assigns.current_scope, character, character_params) do
      {:ok, character} ->
        conn
        |> put_flash(:info, "Character updated successfully.")
        |> redirect(
          to: ~p"/admin/games/#{conn.assigns.current_scope.game}/characters/#{character}"
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, character: character, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    character = Characters.get_character_for_game!(conn.assigns.current_scope, id)
    {:ok, _character} = Characters.delete_character(conn.assigns.current_scope, character)

    conn
    |> put_flash(:info, "Character deleted successfully.")
    |> redirect(to: ~p"/admin/games/#{conn.assigns.current_scope.game}/characters")
  end

  defp load_game(conn, _opts) do
    current_scope = conn.assigns.current_scope

    if game_id = conn.params["game_id"] do
      case Games.fetch_game(current_scope, game_id) do
        {:ok, game} ->
          conn
          |> assign(:game, game)
          |> assign(:current_scope, Scope.put_game(current_scope, game))
          
        {:error, :not_found} ->
          conn
          |> GameMasterCoreWeb.FallbackController.call({:error, :not_found})
          |> halt()
      end
    else
      conn
    end
  end
end
