defmodule GameMasterCoreWeb.QuestJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of quests.
  """
  def index(%{quests: quests}) do
    %{data: for(quest <- quests, do: quest_data(quest))}
  end

  @doc """
  Renders a single quest.
  """
  def show(%{quest: quest}) do
    %{data: quest_data(quest)}
  end

  @doc """
  Renders the quest tree structure.
  """
  def tree(%{tree: tree}) do
    %{data: tree}
  end

  @doc """
  Renders quest links.
  """
  def links(%{
        quest: quest,
        characters: characters,
        factions: factions,
        notes: notes,
        locations: locations,
        quests: quests
      }) do
    %{
      data: %{
        quest_id: quest.id,
        quest_name: quest.name,
        links: %{
          characters: for(character <- characters, do: character_data_with_metadata(character)),
          factions: for(faction <- factions, do: faction_data_with_metadata(faction)),
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          locations: for(location <- locations, do: location_data_with_metadata(location)),
          quests: for(q <- quests, do: quest_data_with_metadata(q))
        }
      }
    }
  end

  @doc """
  Renders shares for an entity.
  """
  def shares(%{shares: shares}) do
    %{
      data: for(share <- shares, do: share_data(share))
    }
  end

  defp share_data(share) do
    %{
      user: %{
        id: share.user.id,
        username: share.user.username,
        email: share.user.email
      },
      permission: share.permission,
      shared_at: share.shared_at
    }
  end
end
