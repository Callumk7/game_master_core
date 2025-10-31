defmodule GameMasterCoreWeb.NoteJSON do
  import GameMasterCoreWeb.JSONHelpers

  @doc """
  Renders a list of notes.
  """
  def index(%{notes: notes}) do
    %{data: for(note <- notes, do: note_data(note))}
  end

  @doc """
  Renders a single note.
  """
  def show(%{note: note}) do
    %{data: note_data(note)}
  end

  @doc """
  Renders a list of links for a note.
  """
  def links(%{
        note: note,
        characters: characters,
        factions: factions,
        locations: locations,
        quests: quests,
        notes: notes
      }) do
    %{
      data: %{
        note_id: note.id,
        note_name: note.name,
        links: %{
          characters: for(character <- characters, do: character_data_with_metadata(character)),
          factions: for(faction <- factions, do: faction_data_with_metadata(faction)),
          locations: for(location <- locations, do: location_data_with_metadata(location)),
          quests: for(quest <- quests, do: quest_data_with_metadata(quest)),
          notes: for(n <- notes, do: note_data_with_metadata(n))
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
