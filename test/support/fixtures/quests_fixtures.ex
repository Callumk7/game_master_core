defmodule GameMasterCore.QuestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Quests` context.
  """

  @doc """
  Generate a quest.
  """
  def quest_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        content: "some content",
        name: "some name"
      })

    {:ok, quest} = GameMasterCore.Quests.create_quest(scope, attrs)
    quest
  end
end
