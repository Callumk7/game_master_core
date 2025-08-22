defmodule GameMasterCoreWeb.Admin.GameController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Games
  alias GameMasterCore.Games.Game

  def index(conn, _params) do
    games = Games.list_games(conn.assigns.current_scope)
    render(conn, :index, games: games)
  end

  def new(conn, _params) do
    changeset =
      Games.change_game(conn.assigns.current_scope, %Game{
        owner_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"game" => game_params}) do
    case Games.create_game(conn.assigns.current_scope, game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created successfully.")
        |> redirect(to: ~p"/admin/games/#{game}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, id)
    render(conn, :show, game: game)
  end

  def edit(conn, %{"id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, id)
    changeset = Games.change_game(conn.assigns.current_scope, game)
    render(conn, :edit, game: game, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    game = Games.get_game!(conn.assigns.current_scope, id)

    case Games.update_game(conn.assigns.current_scope, game, game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated successfully.")
        |> redirect(to: ~p"/admin/games/#{game}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, game: game, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game = Games.get_game!(conn.assigns.current_scope, id)
    {:ok, _game} = Games.delete_game(conn.assigns.current_scope, game)

    conn
    |> put_flash(:info, "Game deleted successfully.")
    |> redirect(to: ~p"/admin/games")
  end
end
