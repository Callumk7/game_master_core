defmodule GameMasterCoreWeb.FactionJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of factions.
  """
  def index(%{factions: factions}) do
    %{data: for(faction <- factions, do: faction_data(faction))}
  end

  @doc """
  Renders a single faction.
  """
  def show(%{faction: faction}) do
    %{data: faction_data(faction)}
  end

  @doc """
  Renders faction links
  """
  def links(%{
        faction: faction,
        notes: notes,
        characters: characters,
        locations: locations,
        quests: quests,
        factions: factions
      }) do
    %{
      data: %{
        faction_id: faction.id,
        faction_name: faction.name,
        links: %{
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          characters: for(character <- characters, do: character_data_with_metadata(character)),
          locations: for(location <- locations, do: location_data_with_metadata(location)),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          factions: for(fact <- factions, do: faction_data_with_metadata(fact))
        }
      }
    }
  end

  @doc """
  Renders faction members
  """
  def members(%{faction: faction, members: members}) do
    %{
      data: %{
        faction_id: faction.id,
        faction_name: faction.name,
        members: for(member <- members, do: character_data(member))
      }
    }
  end

  @doc """
  Renders faction notes tree.
  """
  def notes_tree(%{faction: faction, notes_tree: notes_tree}) do
    %{
      data: %{
        faction_id: faction.id,
        faction_name: faction.name,
        notes_tree: for(note <- notes_tree, do: note_tree_data(note))
      }
    }
  end

  defp note_tree_data(note) do
    note_data(note)
    |> Map.put(:children, for(child <- Map.get(note, :children, []), do: note_tree_data(child)))
    |> Map.put(:entity_type, Map.get(note, :entity_type, "note"))
  end
end
