defmodule GameMasterCore.EntityTree do
  @moduledoc """
  Context module for building entity relationship trees within games.

  This module provides functionality to traverse entity relationships
  and build hierarchical tree structures showing how entities are connected
  through the comprehensive link system.
  """

  import Ecto.Query, warn: false

  alias GameMasterCore.Repo
  alias GameMasterCore.Links
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Notes.Note

  @default_depth 3
  @max_depth 10

  @doc """
  Builds a tree structure of entity relationships for a game.

  Options:
    * `:depth` - Maximum depth to traverse (default: 3, max: 10)
    * `:start_entity_type` - Entity type to start from (optional)
    * `:start_entity_id` - Entity ID to start from (optional)

  If start_entity_type and start_entity_id are provided, builds tree from that entity.
  Otherwise, builds tree from all root entities in the game.

  Returns a list of entity tree nodes with simplified entity data and relationship metadata.
  """
  def build_entity_tree(%Scope{} = scope, opts \\ []) do
    depth = Keyword.get(opts, :depth, @default_depth)
    start_entity_type = Keyword.get(opts, :start_entity_type)
    start_entity_id = Keyword.get(opts, :start_entity_id)

    # Validate depth
    depth = min(max(depth, 1), @max_depth)

    case {start_entity_type, start_entity_id} do
      {nil, nil} ->
        # Build tree from all entities in the game
        build_full_game_tree(scope, depth)

      {entity_type, entity_id} when is_binary(entity_type) and is_binary(entity_id) ->
        # Build tree from specific starting entity
        build_tree_from_entity(scope, entity_type, entity_id, depth)

      _ ->
        {:error, :invalid_start_parameters}
    end
  end

  @doc """
  Builds tree from all entities in a game, grouped by entity type.
  """
  def build_full_game_tree(%Scope{} = scope, depth) do
    # Get all entities for the game
    entities = get_all_game_entities(scope)

    # Build trees for each entity type, sharing visited across types to avoid duplicates
    {results, _final_visited} =
      [
        {:characters, entities.characters},
        {:factions, entities.factions},
        {:locations, entities.locations},
        {:quests, entities.quests},
        {:notes, entities.notes}
      ]
      |> Enum.reduce({%{}, MapSet.new()}, fn {type, type_entities}, {acc_results, acc_visited} ->
        {trees, new_visited} = build_trees_for_entities(type_entities, depth, acc_visited)
        {Map.put(acc_results, type, trees), new_visited}
      end)

    results
  end

  @doc """
  Builds tree from a specific starting entity.
  """
  def build_tree_from_entity(%Scope{} = scope, entity_type, entity_id, depth) do
    with {:ok, entity} <- fetch_entity(scope, entity_type, entity_id) do
      visited = MapSet.new()
      {tree_node, _final_visited} = traverse_entity_links(entity, 0, depth, visited)
      {:ok, tree_node}
    end
  end

  # Private functions

  defp get_all_game_entities(%Scope{} = scope) do
    game_id = scope.game.id

    %{
      characters: from(c in Character, where: c.game_id == ^game_id) |> Repo.all(),
      factions: from(f in Faction, where: f.game_id == ^game_id) |> Repo.all(),
      locations: from(l in Location, where: l.game_id == ^game_id) |> Repo.all(),
      quests: from(q in Quest, where: q.game_id == ^game_id) |> Repo.all(),
      notes: from(n in Note, where: n.game_id == ^game_id) |> Repo.all()
    }
  end

  defp build_trees_for_entities(entities, depth, global_visited) do
    entities
    |> Enum.reduce({[], global_visited}, fn entity, {trees, visited} ->
      entity_key = entity_key(entity)

      if MapSet.member?(visited, entity_key) do
        {trees, visited}
      else
        {tree_node, new_visited} = traverse_entity_links(entity, 0, depth, visited)
        {[tree_node | trees], new_visited}
      end
    end)
    |> then(fn {trees, visited} -> {Enum.reverse(trees), visited} end)
  end

  defp traverse_entity_links(entity, current_depth, max_depth, visited) do
    entity_key = entity_key(entity)

    # Create base node with simplified entity data
    base_node = simplify_entity(entity)

    # If we've reached max depth or already visited this entity, return without children
    if current_depth >= max_depth or MapSet.member?(visited, entity_key) do
      {Map.put(base_node, :children, []), visited}
    else
      # Mark this entity as visited
      new_visited = MapSet.put(visited, entity_key)

      # Get all linked entities using the existing Links module
      links = Links.links_for(entity)

      # Build children from all linked entities, threading visited through each traversal
      {children, final_visited} =
        links
        |> Map.values()
        |> List.flatten()
        |> Enum.reduce({[], new_visited}, fn link_data, {acc_children, acc_visited} ->
          linked_entity = link_data.entity
          linked_entity_key = entity_key(linked_entity)

          # Only traverse if not already visited (cycle detection)
          if MapSet.member?(acc_visited, linked_entity_key) do
            {acc_children, acc_visited}
          else
            {child_node, updated_visited} =
              traverse_entity_links(linked_entity, current_depth + 1, max_depth, acc_visited)

            # Add relationship metadata to the child node
            enriched_child =
              child_node
              |> Map.merge(%{
                relationship_type: link_data.relationship_type,
                description: link_data.description,
                strength: link_data.strength,
                is_active: link_data.is_active,
                metadata: link_data.metadata
              })

            {[enriched_child | acc_children], updated_visited}
          end
        end)

      {Map.put(base_node, :children, Enum.reverse(children)), final_visited}
    end
  end

  defp simplify_entity(entity) do
    %{
      id: entity.id,
      name: entity.name,
      type: get_entity_type(entity)
    }
  end

  defp get_entity_type(%Character{}), do: "character"
  defp get_entity_type(%Faction{}), do: "faction"
  defp get_entity_type(%Location{}), do: "location"
  defp get_entity_type(%Quest{}), do: "quest"
  defp get_entity_type(%Note{}), do: "note"

  defp entity_key(entity) do
    "#{get_entity_type(entity)}_#{entity.id}"
  end

  defp fetch_entity(%Scope{} = scope, "character", entity_id) do
    case Repo.get_by(Character, id: entity_id, game_id: scope.game.id) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  defp fetch_entity(%Scope{} = scope, "faction", entity_id) do
    case Repo.get_by(Faction, id: entity_id, game_id: scope.game.id) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  defp fetch_entity(%Scope{} = scope, "location", entity_id) do
    case Repo.get_by(Location, id: entity_id, game_id: scope.game.id) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  defp fetch_entity(%Scope{} = scope, "quest", entity_id) do
    case Repo.get_by(Quest, id: entity_id, game_id: scope.game.id) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  defp fetch_entity(%Scope{} = scope, "note", entity_id) do
    case Repo.get_by(Note, id: entity_id, game_id: scope.game.id) do
      nil -> {:error, :not_found}
      entity -> {:ok, entity}
    end
  end

  defp fetch_entity(_scope, _entity_type, _entity_id) do
    {:error, :invalid_entity_type}
  end
end
