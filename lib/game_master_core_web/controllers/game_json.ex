defmodule GameMasterCoreWeb.GameJSON do
  alias GameMasterCore.Games.Game

  @doc """
  Renders a list of games.
  """
  def index(%{games: games}) do
    %{data: for(game <- games, do: data(game))}
  end

  @doc """
  Renders a single game.
  """
  def show(%{game: game}) do
    %{data: data(game)}
  end

  @doc """
  Renders a list of members.
  """
  def members(%{members: members}) do
    %{data: for(member <- members, do: member_data(member))}
  end

  defp data(%Game{} = game) do
    %{
      id: game.id,
      name: game.name,
      description: game.description,
      setting: game.setting
    }
  end

  defp member_data(%{user: user, role: role, joined_at: joined_at}) do
    %{
      user_id: user.id,
      email: user.email,
      role: role,
      joined_at: joined_at
    }
  end
end
