defmodule GameMasterCore.ObjectivesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Objectives` context.
  """

  import GameMasterCore.QuestsFixtures

  @doc """
  Generate an objective.
  """
  def objective_fixture(scope, quest \\ nil, attrs \\ %{}) do
    quest = quest || quest_fixture(scope)

    attrs =
      attrs
      |> Enum.into(%{
        body: "some objective body",
        complete: false
      })

    {:ok, objective} =
      GameMasterCore.Objectives.create_objective_for_quest(scope, quest.id, attrs)

    objective
  end

  @doc """
  Generate a completed objective.
  """
  def completed_objective_fixture(scope, quest \\ nil, attrs \\ %{}) do
    attrs = Map.put(attrs, :complete, true)
    objective_fixture(scope, quest, attrs)
  end

  @doc """
  Generate an objective with a note link.
  """
  def objective_with_note_fixture(scope, quest \\ nil, note \\ nil, attrs \\ %{}) do
    import GameMasterCore.NotesFixtures

    quest = quest || quest_fixture(scope)
    note = note || note_fixture(scope)

    attrs = Map.put(attrs, :note_link_id, note.id)
    objective_fixture(scope, quest, attrs)
  end
end
