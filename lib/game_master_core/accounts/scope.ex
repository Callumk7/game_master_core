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
  alias GameMasterCore.Games.Game
  alias GameMasterCore.Authorization

  defstruct user: nil, game: nil, role: nil

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
    role = Authorization.get_user_role(user.id, game)
    %{scope | game: game, role: role}
  end
end
