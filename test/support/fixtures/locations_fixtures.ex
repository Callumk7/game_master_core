defmodule GameMasterCore.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Locations` context.
  """

  @doc """
  Generate a location.
  """
  def location_fixture(scope, attrs \\ %{}) do
    # For backward compatibility, create a game if game_id is not provided
    {updated_scope, game_id} =
      case Map.get(attrs, :game_id) || Map.get(attrs, "game_id") do
        nil ->
          game = GameMasterCore.GamesFixtures.game_fixture(scope)
          {GameMasterCore.Accounts.Scope.put_game(scope, game), game.id}

        id ->
          {scope, id}
      end

    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name",
        type: "city"
      })
      |> Map.put(:game_id, game_id)

    {:ok, location} = GameMasterCore.Locations.create_location(updated_scope, attrs)
    location
  end
end
