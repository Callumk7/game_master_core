defmodule GameMasterCore.CharactersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Characters` context.
  """

  @doc """
  Generate a character.
  """
  def character_fixture(scope, attrs \\ %{}) do
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
        class: "some class",
        content: "some content",
        level: 42,
        name: "some name"
      })
      |> Map.put(:game_id, game_id)

    {:ok, character} = GameMasterCore.Characters.create_character(scope, attrs)
    character
  end
end
