defmodule GameMasterCore.Search do
  @moduledoc """
  The Search context.

  Provides functionality to search across all entity types within a game.
  """

  import Ecto.Query, warn: false
  alias GameMasterCore.Repo
  alias GameMasterCore.Accounts.Scope

  alias GameMasterCore.Characters.Character
  alias GameMasterCore.Factions.Faction
  alias GameMasterCore.Locations.Location
  alias GameMasterCore.Quests.Quest
  alias GameMasterCore.Notes.Note

  @entity_types ["character", "faction", "location", "quest", "note"]
  @default_limit 50
  @max_limit 100

  @doc """
  Search across all entity types within a game.

  ## Options

    * `:entity_types` - List of entity types to search (default: all types)
    * `:tags` - List of tags that must all be present (AND logic)
    * `:pinned_only` - Only return pinned entities (default: false)
    * `:limit` - Maximum results per entity type (default: 50, max: 100)
    * `:offset` - Pagination offset (default: 0)

  ## Examples

      iex> search_game(scope, "dragon", entity_types: ["character", "faction"])
      %{
        query: "dragon",
        total_results: 5,
        filters: %{entity_types: ["character", "faction"], tags: nil, pinned_only: false},
        pagination: %{limit: 50, offset: 0},
        results: %{characters: [...], factions: [...], locations: [], quests: [], notes: []}
      }
  """
  def search_game(%Scope{} = scope, query, opts \\ []) when is_binary(query) do
    entity_types = parse_entity_types(opts[:entity_types])
    tags = opts[:tags]
    pinned_only = opts[:pinned_only] || false
    limit = parse_limit(opts[:limit])
    offset = opts[:offset] || 0

    results = %{
      characters:
        search_if_included(
          "character",
          entity_types,
          scope,
          query,
          tags,
          pinned_only,
          limit,
          offset
        ),
      factions:
        search_if_included(
          "faction",
          entity_types,
          scope,
          query,
          tags,
          pinned_only,
          limit,
          offset
        ),
      locations:
        search_if_included(
          "location",
          entity_types,
          scope,
          query,
          tags,
          pinned_only,
          limit,
          offset
        ),
      quests:
        search_if_included("quest", entity_types, scope, query, tags, pinned_only, limit, offset),
      notes:
        search_if_included("note", entity_types, scope, query, tags, pinned_only, limit, offset)
    }

    total_results =
      Enum.reduce(results, 0, fn {_type, entities}, acc ->
        acc + length(entities)
      end)

    %{
      query: query,
      total_results: total_results,
      filters: %{
        entity_types: entity_types,
        tags: tags,
        pinned_only: pinned_only
      },
      pagination: %{
        limit: limit,
        offset: offset
      },
      results: results
    }
  end

  # Helper to search only if entity type is included
  defp search_if_included(
         entity_type,
         entity_types,
         scope,
         query,
         tags,
         pinned_only,
         limit,
         offset
       ) do
    if entity_type in entity_types do
      search_entity(entity_type, scope, query, tags, pinned_only, limit, offset)
    else
      []
    end
  end

  # Search a specific entity type
  defp search_entity("character", scope, query, tags, pinned_only, limit, offset) do
    build_search_query(Character, scope.game.id, query, tags, pinned_only, limit, offset)
    |> Repo.all()
  end

  defp search_entity("faction", scope, query, tags, pinned_only, limit, offset) do
    build_search_query(Faction, scope.game.id, query, tags, pinned_only, limit, offset)
    |> Repo.all()
  end

  defp search_entity("location", scope, query, tags, pinned_only, limit, offset) do
    build_search_query(Location, scope.game.id, query, tags, pinned_only, limit, offset)
    |> Repo.all()
  end

  defp search_entity("quest", scope, query, tags, pinned_only, limit, offset) do
    build_search_query(Quest, scope.game.id, query, tags, pinned_only, limit, offset)
    |> Repo.all()
  end

  defp search_entity("note", scope, query, tags, pinned_only, limit, offset) do
    build_search_query(Note, scope.game.id, query, tags, pinned_only, limit, offset)
    |> Repo.all()
  end

  # Build the base search query with all filters
  defp build_search_query(schema, game_id, query, tags, pinned_only, limit, offset) do
    search_pattern = "%#{query}%"

    schema
    |> where([e], e.game_id == ^game_id)
    |> where(
      [e],
      ilike(e.name, ^search_pattern) or
        ilike(fragment("COALESCE(?, '')", e.content_plain_text), ^search_pattern)
    )
    |> maybe_filter_by_tags(tags)
    |> maybe_filter_by_pinned(pinned_only)
    |> limit(^limit)
    |> offset(^offset)
    |> order_by([e], desc: e.pinned, asc: e.name)
  end

  # Apply tag filter if tags are provided (AND logic - all tags must be present)
  defp maybe_filter_by_tags(query, nil), do: query
  defp maybe_filter_by_tags(query, []), do: query

  defp maybe_filter_by_tags(query, tags) when is_list(tags) do
    Enum.reduce(tags, query, fn tag, q ->
      where(q, [e], ^tag in e.tags)
    end)
  end

  # Apply pinned filter if requested
  defp maybe_filter_by_pinned(query, false), do: query
  defp maybe_filter_by_pinned(query, true), do: where(query, [e], e.pinned == true)

  # Parse entity types, defaulting to all types
  defp parse_entity_types(nil), do: @entity_types
  defp parse_entity_types([]), do: @entity_types

  defp parse_entity_types(types) when is_list(types) do
    types
    |> Enum.filter(&(&1 in @entity_types))
    |> case do
      [] -> @entity_types
      filtered -> filtered
    end
  end

  # Parse limit with validation
  defp parse_limit(nil), do: @default_limit
  defp parse_limit(limit) when is_integer(limit) and limit > 0 and limit <= @max_limit, do: limit
  defp parse_limit(limit) when is_integer(limit) and limit > @max_limit, do: @max_limit
  defp parse_limit(_), do: @default_limit
end
