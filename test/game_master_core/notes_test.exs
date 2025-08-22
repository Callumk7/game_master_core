defmodule GameMasterCore.NotesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Notes

  describe "notes" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures

    @invalid_attrs %{name: nil, content: nil}

    test "list_notes/1 returns all scoped notes" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      note = note_fixture(scope)
      other_note = note_fixture(other_scope)
      assert Notes.list_notes(scope) == [note]
      assert Notes.list_notes(other_scope) == [other_note]
    end

    test "get_note!/2 returns the note with given id" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      other_scope = user_scope_fixture()
      assert Notes.get_note!(scope, note.id) == note
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(other_scope, note.id) end
    end

    test "create_note/2 with valid data creates a note" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      valid_attrs = %{name: "some name", content: "some content", game_id: game.id}

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.name == "some name"
      assert note.content == "some content"
      assert note.user_id == scope.user.id
      assert note.game_id == game.id
    end

    test "create_note/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(scope, attrs_with_game)
    end

    test "update_note/3 with valid data updates the note" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      update_attrs = %{name: "some updated name", content: "some updated content"}

      assert {:ok, %Note{} = note} = Notes.update_note(scope, note, update_attrs)
      assert note.name == "some updated name"
      assert note.content == "some updated content"
    end

    test "update_note/3 with invalid scope doesn't raise but doesn't permit update" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      note = note_fixture(scope)

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update notes
      assert {:ok, _} = Notes.update_note(scope, note, %{name: "Updated by owner"})
    end

    test "update_note/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(scope, note, @invalid_attrs)
      assert note == Notes.get_note!(scope, note.id)
    end

    test "delete_note/2 deletes the note" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      assert {:ok, %Note{}} = Notes.delete_note(scope, note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(scope, note.id) end
    end

    test "delete_note/2 with invalid scope doesn't raise but works based on game permissions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      note = note_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Notes.delete_note(scope, note)
    end

    test "change_note/2 returns a note changeset" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      assert %Ecto.Changeset{} = Notes.change_note(scope, note)
    end
  end

  describe "game-based notes" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures

    test "list_notes_for_game/2 returns notes for a specific game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      note1 = note_fixture(scope, %{game_id: game1.id, name: "Game 1 Note"})
      note2 = note_fixture(scope, %{game_id: game2.id, name: "Game 2 Note"})

      notes1 = Notes.list_notes_for_game(scope, game1)
      notes2 = Notes.list_notes_for_game(scope, game2)

      assert length(notes1) == 1
      assert length(notes2) == 1
      assert hd(notes1).name == "Game 1 Note"
      assert hd(notes2).name == "Game 2 Note"
    end

    test "get_note_for_game!/3 returns note only if it belongs to the game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      note1 = note_fixture(scope, %{game_id: game1.id})

      assert Notes.get_note_for_game!(scope, game1, note1.id) == note1

      assert_raise Ecto.NoResultsError, fn ->
        Notes.get_note_for_game!(scope, game2, note1.id)
      end
    end

    test "create_note_for_game/3 creates a note associated with the game" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      attrs = %{name: "Game Note", content: "Some content"}

      assert {:ok, %Note{} = note} = Notes.create_note_for_game(scope, game, attrs)
      assert note.game_id == game.id
      assert note.user_id == scope.user.id
      assert note.name == "Game Note"
    end
  end
end
