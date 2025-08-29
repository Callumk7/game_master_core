defmodule GameMasterCore.QuestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Quests` context.
  """

  @doc """
  Generate a quest.
  """
  def quest_fixture(scope, attrs \\ %{}) do
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
        name: "some name",
        content: "some content"
      })
      |> Map.put(:game_id, game_id)

    {:ok, quest} = GameMasterCore.Quests.create_quest(scope, attrs)
    quest
  end
end
