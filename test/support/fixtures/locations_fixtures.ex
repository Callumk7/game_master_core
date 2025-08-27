defmodule GameMasterCore.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Locations` context.
  """

  @doc """
  Generate a location.
  """
  def location_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name",
        type: "some type"
      })

    {:ok, location} = GameMasterCore.Locations.create_location(scope, attrs)
    location
  end
end
