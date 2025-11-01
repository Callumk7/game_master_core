defmodule GameMasterCore.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `GameMasterCore.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias GameMasterCore.Accounts.User
  alias GameMasterCore.Games.{Game, GameMembership}
  alias GameMasterCore.Repo

  defstruct user: nil, game: nil, role: nil

  @type t :: %__MODULE__{
          user: User.t() | nil,
          game: Game.t() | nil,
          role: :admin | :game_master | :member | nil
        }

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Adds game context to scope and determines user's role in that game.

  The role is automatically resolved based on:
  1. Game ownership (game.owner_id) -> :admin
  2. GameMembership role -> :admin, :game_master, or :member
  3. Not a member -> nil

  ## Examples

      iex> scope = Scope.for_user(user)
      iex> scope = Scope.put_game(scope, game)
      iex> scope.role
      :admin  # or :game_master, :member, nil
  """
  def put_game(%__MODULE__{user: user} = scope, %Game{} = game) do
    role = determine_role(user.id, game)
    %{scope | game: game, role: role}
  end

  # Role resolution logic (moved from Authorization to break circular dependency)

  defp determine_role(user_id, %Game{owner_id: owner_id}) when user_id == owner_id do
    :admin
  end

  defp determine_role(user_id, %Game{id: game_id}) do
    case Repo.get_by(GameMembership, user_id: user_id, game_id: game_id) do
      nil -> nil
      %{role: "admin"} -> :admin
      %{role: "game_master"} -> :game_master
      %{role: "member"} -> :member
      %{role: "owner"} -> :admin  # Backward compatibility
    end
  end
end
