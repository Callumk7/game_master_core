defmodule GameMasterCoreWeb.LocationJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of locations.
  """
  def index(%{locations: locations}) do
    %{data: for(location <- locations, do: location_data(location))}
  end

  @doc """
  Renders a single location.
  """
  def show(%{location: location}) do
    %{data: location_data(location)}
  end

  @doc """
  Renders the location tree structure.
  """
  def tree(%{tree: tree}) do
    %{data: tree}
  end

  def links(%{
        location: location,
        notes: notes,
        factions: factions,
        characters: characters,
        quests: quests,
        locations: locations
      }) do
    %{
      data: %{
        location_id: location.id,
        location_name: location.name,
        location_type: location.type,
        links: %{
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          factions:
            for(faction <- factions, do: faction_data_with_metadata_with_location(faction)),
          characters:
            for(
              character <- characters,
              do: character_data_with_metadata_with_location(character)
            ),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          locations: for(loc <- locations, do: location_data_with_metadata(loc))
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
