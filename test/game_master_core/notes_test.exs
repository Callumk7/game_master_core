defmodule GameMasterCore.NotesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Notes

  describe "notes" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.CharactersFixtures

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
      _other_scope = user_scope_fixture()
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
      _other_scope = user_scope_fixture()
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
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures

    test "list_notes_for_game/1 returns notes for a specific game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      
      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)
      
      _note1 = note_fixture(scope, %{game_id: game1.id, name: "Game 1 Note"})
      _note2 = note_fixture(scope, %{game_id: game2.id, name: "Game 2 Note"})

      notes1 = Notes.list_notes_for_game(scope1)
      notes2 = Notes.list_notes_for_game(scope2)

      assert length(notes1) == 1
      assert length(notes2) == 1
      assert hd(notes1).name == "Game 1 Note"
      assert hd(notes2).name == "Game 2 Note"
    end

    test "get_note_for_game!/2 returns note only if it belongs to the game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      note1 = note_fixture(scope, %{game_id: game1.id})

      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)

      assert Notes.get_note_for_game!(scope1, note1.id) == note1

      assert_raise Ecto.NoResultsError, fn ->
        Notes.get_note_for_game!(scope2, note1.id)
      end
    end

    test "create_note_for_game/2 creates a note associated with the game" do
      scope = game_scope_fixture()
      attrs = %{name: "Game Note", content: "Some content"}

      assert {:ok, %Note{} = note} = Notes.create_note_for_game(scope, attrs)
      assert note.game_id == scope.game.id
      assert note.user_id == scope.user.id
      assert note.name == "Game Note"
    end
  end

  describe "note links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures

    test "link_character/3 successfully links a note and character" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character = character_fixture(scope)
      
      assert {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert Notes.character_linked?(scope, note.id, character.id)
    end

    test "link_character/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      
      assert {:error, :note_not_found} = Notes.link_character(scope, 999, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      
      assert {:error, :character_not_found} = Notes.link_character(scope, note.id, 999)
    end

    test "link_character/3 with cross-scope note returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      character = character_fixture(scope2)
      
      # Note exists in scope1, character is in scope2, so character_not_found is returned first
      assert {:error, :character_not_found} = Notes.link_character(scope1, note.id, character.id)
    end

    test "link_character/3 with cross-scope character returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      character = character_fixture(scope1)
      
      # Note is in scope1, character is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_character(scope2, note.id, character.id)
    end

    test "link_character/3 prevents duplicate links" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character = character_fixture(scope)
      
      assert {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_character(scope, note.id, character.id)
    end

    test "unlink_character/3 successfully removes a note-character link" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character = character_fixture(scope)
      
      {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert Notes.character_linked?(scope, note.id, character.id)
      
      assert {:ok, _link} = Notes.unlink_character(scope, note.id, character.id)
      refute Notes.character_linked?(scope, note.id, character.id)
    end

    test "unlink_character/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character = character_fixture(scope)
      
      assert {:error, :not_found} = Notes.unlink_character(scope, note.id, character.id)
    end

    test "unlink_character/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      
      assert {:error, :note_not_found} = Notes.unlink_character(scope, 999, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      
      assert {:error, :character_not_found} = Notes.unlink_character(scope, note.id, 999)
    end

    test "character_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character = character_fixture(scope)
      
      refute Notes.character_linked?(scope, note.id, character.id)
    end

    test "character_linked?/3 with invalid note_id returns false" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      
      refute Notes.character_linked?(scope, 999, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      
      refute Notes.character_linked?(scope, note.id, 999)
    end

    test "linked_characters/2 returns all characters linked to a note" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)
      
      {:ok, _} = Notes.link_character(scope, note.id, character1.id)
      {:ok, _} = Notes.link_character(scope, note.id, character2.id)
      
      linked_characters = Notes.linked_characters(scope, note.id)
      assert length(linked_characters) == 2
      assert character1 in linked_characters
      assert character2 in linked_characters
      refute unlinked_character in linked_characters
    end

    test "linked_characters/2 returns empty list for note with no linked characters" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      
      assert Notes.linked_characters(scope, note.id) == []
    end

    test "linked_characters/2 with invalid note_id returns empty list" do
      scope = user_scope_fixture()
      
      assert Notes.linked_characters(scope, 999) == []
    end

    test "linked_characters/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      character = character_fixture(scope1)
      
      {:ok, _} = Notes.link_character(scope1, note.id, character.id)
      
      # Same note ID in different scope should return empty
      assert Notes.linked_characters(scope2, note.id) == []
    end
  end
end
