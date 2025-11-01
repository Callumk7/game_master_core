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
  Includes user's role if scope is provided.
  """
  def show(%{game: game, scope: scope}) do
    %{data: game_data(game, scope)}
  end

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

  @doc """
  Renders the entity tree structure.
  """
  def tree(%{tree: tree}) do
    %{data: format_tree_data(tree)}
  end

  # Helper function to format tree data recursively
  defp format_tree_data(tree) when is_map(tree) and not is_struct(tree) do
    # Handle full game tree (map with entity type keys)
    if Map.has_key?(tree, :characters) do
      %{
        characters: Enum.map(tree.characters, &format_tree_node/1),
        factions: Enum.map(tree.factions, &format_tree_node/1),
        locations: Enum.map(tree.locations, &format_tree_node/1),
        quests: Enum.map(tree.quests, &format_tree_node/1),
        notes: Enum.map(tree.notes, &format_tree_node/1)
      }
    else
      # Handle single tree node
      format_tree_node(tree)
    end
  end

  defp format_tree_data(tree), do: format_tree_node(tree)

  defp format_tree_node(node) when is_map(node) do
    base_data = %{
      id: node.id,
      name: node.name,
      type: node.type
    }

    # Add relationship metadata if present
    metadata_fields = [:relationship_type, :description, :strength, :is_active, :metadata]

    relationship_data =
      metadata_fields
      |> Enum.reduce(%{}, fn field, acc ->
        case Map.get(node, field) do
          nil -> acc
          value -> Map.put(acc, field, value)
        end
      end)

    # Add children
    children =
      case Map.get(node, :children, []) do
        children when is_list(children) ->
          Enum.map(children, &format_tree_node/1)

        _ ->
          []
      end

    base_data
    |> Map.merge(relationship_data)
    |> Map.put(:children, children)
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
