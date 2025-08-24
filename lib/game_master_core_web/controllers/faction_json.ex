defmodule GameMasterCoreWeb.FactionJSON do
  alias GameMasterCore.Factions.Faction

  @doc """
  Renders a list of factions.
  """
  def index(%{factions: factions}) do
    %{data: for(faction <- factions, do: data(faction))}
  end

  @doc """
  Renders a single faction.
  """
  def show(%{faction: faction}) do
    %{data: data(faction)}
  end

  defp data(%Faction{} = faction) do
    %{
      id: faction.id,
      name: faction.name,
      description: faction.description
    }
  end
end
