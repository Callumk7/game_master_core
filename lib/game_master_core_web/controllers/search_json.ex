defmodule GameMasterCoreWeb.SearchJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders search results.
  """
  def search(%{results: results}) do
    %{
      data: %{
        query: results.query,
        total_results: results.total_results,
        filters: %{
          entity_types: results.filters.entity_types,
          tags: results.filters.tags,
          pinned_only: results.filters.pinned_only
        },
        pagination: %{
          limit: results.pagination.limit,
          offset: results.pagination.offset
        },
        results: %{
          characters: for(character <- results.results.characters, do: character_data(character)),
          factions: for(faction <- results.results.factions, do: faction_data(faction)),
          locations: for(location <- results.results.locations, do: location_data(location)),
          quests: for(quest <- results.results.quests, do: quest_data(quest)),
          notes: for(note <- results.results.notes, do: note_data(note))
        }
      }
    }
  end
end
