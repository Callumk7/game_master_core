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

  def entities(%{game: game, entities: entities, fields: fields}) do
    %{
      data: %{
        game_id: game.id,
        game_name: game.name,
        entities: %{
          notes: for(note <- entities.notes, do: entity_data_for_fields(note, :note, fields)),
          characters:
            for(
              character <- entities.characters,
              do: entity_data_for_fields(character, :character, fields)
            ),
          factions:
            for(
              faction <- entities.factions,
              do: entity_data_for_fields(faction, :faction, fields)
            ),
          locations:
            for(
              location <- entities.locations,
              do: entity_data_for_fields(location, :location, fields)
            ),
          quests: for(quest <- entities.quests, do: entity_data_for_fields(quest, :quest, fields))
        }
      }
    }
  end

  # Fallback for backwards compatibility when fields is not provided
  def entities(%{game: game, entities: entities}) do
    entities(%{game: game, entities: entities, fields: :all})
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

  # Helper to select entity data based on fields parameter
  defp entity_data_for_fields(entity, entity_type, :all) do
    # Full data with all fields
    case entity_type do
      :note -> note_data(entity)
      :character -> character_data(entity)
      :faction -> faction_data(entity)
      :location -> location_data(entity)
      :quest -> quest_data(entity)
    end
  end

  defp entity_data_for_fields(entity, entity_type, :minimal) do
    # Minimal data: id, name, game_id only
    base_minimal = %{
      id: entity.id,
      name: entity.name,
      game_id: entity.game_id
    }

    # Add entity-specific required fields
    case entity_type do
      :character ->
        Map.merge(base_minimal, %{
          class: entity.class,
          level: entity.level
        })

      :location ->
        Map.merge(base_minimal, %{
          type: entity.type
        })

      :quest ->
        Map.merge(base_minimal, %{
          status: entity.status
        })

      _ ->
        base_minimal
    end
  end

  defp entity_data_for_fields(entity, entity_type, :plain_text) do
    # Plain text: id, name, content_plain_text, and required fields
    base_plain_text = %{
      id: entity.id,
      name: entity.name,
      game_id: entity.game_id,
      content_plain_text: entity.content_plain_text
    }

    # Add entity-specific required fields
    case entity_type do
      :character ->
        Map.merge(base_plain_text, %{
          class: entity.class,
          level: entity.level
        })

      :location ->
        Map.merge(base_plain_text, %{
          type: entity.type
        })

      :quest ->
        Map.merge(base_plain_text, %{
          status: entity.status
        })

      _ ->
        base_plain_text
    end
  end
end
