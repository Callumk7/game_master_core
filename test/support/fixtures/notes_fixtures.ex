defmodule GameMasterCore.NotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameMasterCore.Notes` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(scope, attrs \\ %{}) do
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
      attrs
      |> Enum.into(%{
        content: "some content",
        name: "some name"
      })
      |> Map.put(:game_id, game_id)

    {:ok, note} = GameMasterCore.Notes.create_note(scope, attrs)
    note
  end
end
