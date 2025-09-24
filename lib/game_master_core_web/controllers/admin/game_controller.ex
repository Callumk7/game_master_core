defmodule GameMasterCoreWeb.Admin.GameController do
  use GameMasterCoreWeb, :controller
  import Phoenix.Component, only: [to_form: 1]

  alias GameMasterCore.Games
  alias GameMasterCore.Games.Game

  action_fallback GameMasterCoreWeb.FallbackController

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
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id) do
      render(conn, :show, game: game)
    end
  end

  def edit(conn, %{"id" => id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id) do
      changeset = Games.change_game(conn.assigns.current_scope, game)
      render(conn, :edit, game: game, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id) do
      case Games.update_game(conn.assigns.current_scope, game, game_params) do
        {:ok, game} ->
          conn
          |> put_flash(:info, "Game updated successfully.")
          |> redirect(to: ~p"/admin/games/#{game}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, game: game, changeset: changeset)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, id),
         {:ok, _game} <- Games.delete_game(conn.assigns.current_scope, game) do
      conn
      |> put_flash(:info, "Game deleted successfully.")
      |> redirect(to: ~p"/admin/games")
    end
  end

  def list_members(conn, %{"game_id" => game_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      members = Games.list_members(conn.assigns.current_scope, game)
      form = to_form(%{"user_id" => "", "role" => "member"})
      render(conn, :list_members, game: game, members: members, form: form)
    end
  end

  def add_member(conn, %{"game_id" => game_id, "user_id" => user_id, "role" => role}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      case Games.add_member(conn.assigns.current_scope, game, String.to_integer(user_id), role) do
        {:ok, _membership} ->
          conn
          |> put_flash(:info, "Member added successfully.")
          |> redirect(to: ~p"/admin/games/#{game_id}/members")

        {:error, :unauthorized} ->
          conn
          |> put_flash(:error, "You are not authorized to add members to this game.")
          |> redirect(to: ~p"/admin/games/#{game_id}/members")

        {:error, changeset} ->
          members = Games.list_members(conn.assigns.current_scope, game)
          render(conn, :list_members, game: game, members: members, changeset: changeset)
      end
    end
  end

  def remove_member(conn, %{"game_id" => game_id, "user_id" => user_id}) do
    with {:ok, game} <- Games.fetch_game(conn.assigns.current_scope, game_id) do
      case Games.remove_member(conn.assigns.current_scope, game, String.to_integer(user_id)) do
        {:ok, _membership} ->
          conn
          |> put_flash(:info, "Member removed successfully.")
          |> redirect(to: ~p"/admin/games/#{game_id}/members")

        {:error, :not_found} ->
          conn
          |> put_flash(:error, "Member not found.")
          |> redirect(to: ~p"/admin/games/#{game_id}/members")
      end
    end
  end
end
