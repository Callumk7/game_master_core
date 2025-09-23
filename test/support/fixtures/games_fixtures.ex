defmodule GameMasterCore.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        content: "some content",
        name: "some name",
        setting: "some setting"
      })

    {:ok, game} = GameMasterCore.Games.create_game(scope, attrs)
    game
  end
end
