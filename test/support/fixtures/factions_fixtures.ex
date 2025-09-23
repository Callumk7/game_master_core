defmodule GameMasterCore.FactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Factions` context.
  """

  @doc """
  Generate a faction.
  """
  def faction_fixture(scope, attrs \\ %{}) do
    # For backward compatibility, create a game if game_id is not provided
    game_id =
      case Map.get(attrs, :game_id) || Map.get(attrs, "game_id") do
        nil ->
          game = GameMasterCore.GamesFixtures.game_fixture(scope)
          game.id

        id ->
          id
      end

    attrs =
      Enum.into(attrs, %{
        content: "some content",
        name: "some name"
      })
      |> Map.put(:game_id, game_id)

    {:ok, faction} = GameMasterCore.Factions.create_faction(scope, attrs)
    faction
  end
end
