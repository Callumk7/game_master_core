defmodule GameMasterCoreWeb.CharacterJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of characters.
  """
  def index(%{characters: characters}) do
    %{data: for(character <- characters, do: character_data(character))}
  end

  @doc """
  Renders a single character.
  Permission metadata is included if populated by context layer.
  """
  def show(%{character: character}) do
    %{data: character_data(character)}
  end

  @doc """
  Renders character links.
  """
  def links(%{
        character: character,
        notes: notes,
        factions: factions,
        locations: locations,
        quests: quests,
        characters: characters
      }) do
    %{
      data: %{
        character_id: character.id,
        character_name: character.name,
        links: %{
          notes: for(note <- notes, do: note_data_with_metadata(note)),
          factions:
            for(faction <- factions, do: faction_data_with_metadata_with_faction(faction)),
          locations:
            for(
              location <- locations,
              do: location_data_with_metadata_with_current_location(location)
            ),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          characters: for(char <- characters, do: character_data_with_metadata(char))
        }
      }
    }
  end

  @doc """
  Renders primary faction data for a character.
  """
  def primary_faction(%{primary_faction_data: primary_faction_data}) do
    %{
      data: %{
        character_id: primary_faction_data.character_id,
        faction: faction_data(primary_faction_data.faction),
        role: primary_faction_data.role
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
