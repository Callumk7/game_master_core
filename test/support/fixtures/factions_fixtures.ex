defmodule GameMasterCore.FactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Factions` context.
  """

  @doc """
  Generate a faction.
  """
  def faction_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, faction} = GameMasterCore.Factions.create_faction(scope, attrs)
    faction
  end
end
