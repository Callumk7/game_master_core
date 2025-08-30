defmodule GameMasterCoreWeb.GameJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of games.
  """
  def index(%{games: games}) do
    %{data: for(game <- games, do: game_data(game))}
  end

  @doc """
  Renders a single game.
  """
  def show(%{game: game}) do
    %{data: game_data(game)}
  end

  @doc """
  Renders a list of members.
  """
  def members(%{members: members}) do
    %{data: for(member <- members, do: member_data(member))}
  end

  def entities(%{game: game, entities: entities}) do
    %{
      data: %{
        game_id: game.id,
        game_name: game.name,
        entities: %{
          notes: for(note <- entities.notes, do: note_data(note)),
          characters: for(character <- entities.characters, do: character_data(character)),
          factions: for(faction <- entities.factions, do: faction_data(faction)),
          locations: for(location <- entities.locations, do: location_data(location)),
          quests: for(quest <- entities.quests, do: quest_data(quest))
        }
      }
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
