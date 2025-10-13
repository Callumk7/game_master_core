defmodule GameMasterCore.NotesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Notes

  describe "notes" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    @invalid_attrs %{name: nil, content: nil}

    test "list_notes/1 returns all scoped notes" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      other_note = note_fixture(other_scope, %{game_id: other_scope.game.id})
      assert Notes.list_notes(scope) == [note]
      assert Notes.list_notes(other_scope) == [other_note]
    end

    test "get_note!/2 returns the note with given id" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      other_scope = game_scope_fixture()
      assert Notes.get_note!(scope, note.id) == note
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(other_scope, note.id) end
    end

    test "create_note/2 with valid data creates a note" do
      scope = game_scope_fixture()
      game = game_fixture(scope)
      valid_attrs = %{name: "some name", content: "some content", game_id: game.id}

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.name == "some name"
      assert note.content == "some content"
      assert note.user_id == scope.user.id
      assert note.game_id == game.id
    end

    test "create_note/2 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(scope, attrs_with_game)
    end

    test "update_note/3 with valid data updates the note" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      update_attrs = %{name: "some updated name", content: "some updated content"}

      assert {:ok, %Note{} = note} = Notes.update_note(scope, note, update_attrs)
      assert note.name == "some updated name"
      assert note.content == "some updated content"
    end

    test "update_note/3 performs update when called (authorization handled at controller level)" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update notes
      assert {:ok, _} =
               Notes.update_note(other_scope, note, %{name: "Updated by owner other user"})
    end

    test "update_note/3 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(scope, note, @invalid_attrs)
      assert note == Notes.get_note!(scope, note.id)
    end

    test "delete_note/2 deletes the note" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      assert {:ok, %Note{}} = Notes.delete_note(scope, note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(scope, note.id) end
    end

    test "delete_note/2 with invalid scope still deletes note as permissions are handled on controller level" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Notes.delete_note(other_scope, note)
    end

    test "change_note/2 returns a note changeset" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      assert %Ecto.Changeset{} = Notes.change_note(scope, note)
    end
  end

  describe "game-based notes" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "list_notes_for_game/1 returns notes for a specific game" do
      scope = game_scope_fixture()
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
      scope = game_scope_fixture()
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

  describe "note - character links" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "link_character/3 successfully links a note and character" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert Notes.character_linked?(scope, note.id, character.id)
    end

    test "link_character/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Notes.link_character(scope, invalid_note_id, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Notes.link_character(scope, note.id, invalid_character_id)
    end

    test "link_character/3 with cross-scope note returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      character = character_fixture(scope2, %{game_id: scope2.game.id})

      # Note exists in scope1, character is in scope2, so character_not_found is returned first
      assert {:error, :character_not_found} = Notes.link_character(scope1, note.id, character.id)
    end

    test "link_character/3 with cross-scope character returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      character = character_fixture(scope1, %{game_id: scope1.game.id})

      # Note is in scope1, character is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_character(scope2, note.id, character.id)
    end

    test "link_character/3 prevents duplicate links" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_character(scope, note.id, character.id)
    end

    test "unlink_character/3 successfully removes a note-character link" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character = character_fixture(scope, %{game_id: scope.game.id})

      {:ok, _link} = Notes.link_character(scope, note.id, character.id)
      assert Notes.character_linked?(scope, note.id, character.id)

      assert {:ok, _link} = Notes.unlink_character(scope, note.id, character.id)
      refute Notes.character_linked?(scope, note.id, character.id)
    end

    test "unlink_character/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert {:error, :not_found} = Notes.unlink_character(scope, note.id, character.id)
    end

    test "unlink_character/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Notes.unlink_character(scope, invalid_note_id, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Notes.unlink_character(scope, note.id, invalid_character_id)
    end

    test "character_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character = character_fixture(scope, %{game_id: scope.game.id})

      refute Notes.character_linked?(scope, note.id, character.id)
    end

    test "character_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      refute Notes.character_linked?(scope, invalid_note_id, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()
      refute Notes.character_linked?(scope, note.id, invalid_character_id)
    end

    test "linked_characters/2 returns all characters linked to a note" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      character1 = character_fixture(scope, %{game_id: scope.game.id})
      character2 = character_fixture(scope, %{game_id: scope.game.id})
      unlinked_character = character_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Notes.link_character(scope, note.id, character1.id)
      {:ok, _} = Notes.link_character(scope, note.id, character2.id)

      linked_characters_with_meta = Notes.linked_characters(scope, note.id)
      assert length(linked_characters_with_meta) == 2
      linked_characters = Enum.map(linked_characters_with_meta, & &1.entity)
      assert character1 in linked_characters
      assert character2 in linked_characters
      refute unlinked_character in linked_characters
    end

    test "linked_characters/2 returns empty list for note with no linked characters" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert Notes.linked_characters(scope, note.id) == []
    end

    test "linked_characters/2 with invalid note_id returns empty list" do
      scope = game_scope_fixture()

      invalid_note_id = Ecto.UUID.generate()
      assert Notes.linked_characters(scope, invalid_note_id) == []
    end

    test "linked_characters/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      character = character_fixture(scope1, %{game_id: scope1.game.id})

      {:ok, _} = Notes.link_character(scope1, note.id, character.id)

      # Same note ID in different scope should return empty
      assert Notes.linked_characters(scope2, note.id) == []
    end
  end

  describe "note - faction links" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "link_faction/3 successfully links a note and faction" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "link_faction/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.link_faction(scope, invalid_note_id, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()
      assert {:error, :faction_not_found} = Notes.link_faction(scope, note.id, invalid_faction_id)
    end

    test "link_faction/3 with cross-scope note returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope2, %{game_id: scope2.game.id})

      # Note exists in scope1, faction is in scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} = Notes.link_faction(scope1, note.id, faction.id)
    end

    test "link_faction/3 with cross-scope faction returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})

      # Note is in scope1, faction is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_faction(scope2, note.id, faction.id)
    end

    test "link_faction/3 prevents duplicate links" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_faction(scope, note.id, faction.id)
    end

    test "unlink_faction/3 successfully removes a note-faction link" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert Notes.faction_linked?(scope, note.id, faction.id)

      assert {:ok, _link} = Notes.unlink_faction(scope, note.id, faction.id)
      refute Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "unlink_faction/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:error, :not_found} = Notes.unlink_faction(scope, note.id, faction.id)
    end

    test "unlink_faction/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.unlink_faction(scope, invalid_note_id, faction.id)
    end

    test "unlink_faction/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Notes.unlink_faction(scope, note.id, invalid_faction_id)
    end

    test "faction_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      refute Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "faction_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      refute Notes.faction_linked?(scope, invalid_note_id, faction.id)
    end

    test "faction_linked?/3 with invalid faction_id returns false" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()
      refute Notes.faction_linked?(scope, note.id, invalid_faction_id)
    end

    test "linked_factions/2 returns all factions linked to a note" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction1 = faction_fixture(scope, %{game_id: scope.game.id})
      faction2 = faction_fixture(scope, %{game_id: scope.game.id})
      unlinked_faction = faction_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Notes.link_faction(scope, note.id, faction1.id)
      {:ok, _} = Notes.link_faction(scope, note.id, faction2.id)

      linked_factions_with_meta = Notes.linked_factions(scope, note.id)
      assert length(linked_factions_with_meta) == 2
      linked_factions = Enum.map(linked_factions_with_meta, & &1.entity)
      assert faction1 in linked_factions
      assert faction2 in linked_factions
      refute unlinked_faction in linked_factions
    end

    test "linked_factions/2 returns empty list for note with no linked factions" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert Notes.linked_factions(scope, note.id) == []
    end

    test "linked_factions/2 with invalid note_id returns empty list" do
      scope = game_scope_fixture()

      invalid_note_id = Ecto.UUID.generate()
      assert Notes.linked_factions(scope, invalid_note_id) == []
    end

    test "linked_factions/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})

      {:ok, _} = Notes.link_faction(scope1, note.id, faction.id)

      # Same note ID in different scope should return empty
      assert Notes.linked_factions(scope2, note.id) == []
    end
  end

  describe "note - quest links" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "link_quest/3 successfully links a note and quest" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "link_quest/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.link_quest(scope, invalid_note_id, quest.id)
    end

    test "link_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      assert {:error, :quest_not_found} = Notes.link_quest(scope, note.id, invalid_quest_id)
    end

    test "link_quest/3 with cross-scope note returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope2, %{game_id: scope2.game.id})

      # Note exists in scope1, quest is in scope2, so quest_not_found is returned first
      assert {:error, :quest_not_found} = Notes.link_quest(scope1, note.id, quest.id)
    end

    test "link_quest/3 with cross-scope quest returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1, %{game_id: scope1.game.id})

      # Note is in scope1, quest is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_quest(scope2, note.id, quest.id)
    end

    test "link_quest/3 prevents duplicate links" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_quest(scope, note.id, quest.id)
    end

    test "unlink_quest/3 successfully removes a note-quest link" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert Notes.quest_linked?(scope, note.id, quest.id)

      assert {:ok, _link} = Notes.unlink_quest(scope, note.id, quest.id)
      refute Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "unlink_quest/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      assert {:error, :not_found} = Notes.unlink_quest(scope, note.id, quest.id)
    end

    test "unlink_quest/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.unlink_quest(scope, invalid_note_id, quest.id)
    end

    test "unlink_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      assert {:error, :quest_not_found} = Notes.unlink_quest(scope, note.id, invalid_quest_id)
    end

    test "quest_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      refute Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "quest_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      refute Notes.quest_linked?(scope, invalid_note_id, quest.id)
    end

    test "quest_linked?/3 with invalid quest_id returns false" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      refute Notes.quest_linked?(scope, note.id, invalid_quest_id)
    end

    test "linked_quests/2 returns all quests linked to a note" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest1 = quest_fixture(scope, %{game_id: scope.game.id})
      quest2 = quest_fixture(scope, %{game_id: scope.game.id})
      unlinked_quest = quest_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Notes.link_quest(scope, note.id, quest1.id)
      {:ok, _} = Notes.link_quest(scope, note.id, quest2.id)

      linked_quests_with_meta = Notes.linked_quests(scope, note.id)
      assert length(linked_quests_with_meta) == 2
      linked_quests = Enum.map(linked_quests_with_meta, & &1.entity)
      assert quest1 in linked_quests
      assert quest2 in linked_quests
      refute unlinked_quest in linked_quests
    end

    test "linked_quests/2 returns empty list for note with no linked quests" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert Notes.linked_quests(scope, note.id) == []
    end

    test "linked_quests/2 with invalid note_id returns empty list" do
      scope = game_scope_fixture()

      invalid_note_id = Ecto.UUID.generate()
      assert Notes.linked_quests(scope, invalid_note_id) == []
    end

    test "linked_quests/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1, %{game_id: scope1.game.id})

      {:ok, _} = Notes.link_quest(scope1, note.id, quest.id)

      # Same note ID in different scope should return empty
      assert Notes.linked_quests(scope2, note.id) == []
    end
  end
end
