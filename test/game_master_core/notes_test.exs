defmodule GameMasterCore.NotesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Notes

  describe "notes" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

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

    test "update_note/3 performs update when called (authorization handled at controller level)" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      note = note_fixture(scope)

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update notes
      assert {:ok, _} =
               Notes.update_note(other_scope, note, %{name: "Updated by owner other user"})
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

    test "delete_note/2 with invalid scope still deletes note as permissions are handled on controller level" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      note = note_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Notes.delete_note(other_scope, note)
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
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

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

  describe "note - character links" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

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

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Notes.link_character(scope, invalid_note_id, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Notes.link_character(scope, note.id, invalid_character_id)
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

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Notes.unlink_character(scope, invalid_note_id, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Notes.unlink_character(scope, note.id, invalid_character_id)
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

      invalid_note_id = Ecto.UUID.generate()
      refute Notes.character_linked?(scope, invalid_note_id, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()
      refute Notes.character_linked?(scope, note.id, invalid_character_id)
    end

    test "linked_characters/2 returns all characters linked to a note" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)

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
      scope = user_scope_fixture()
      note = note_fixture(scope)

      assert Notes.linked_characters(scope, note.id) == []
    end

    test "linked_characters/2 with invalid note_id returns empty list" do
      scope = user_scope_fixture()

      invalid_note_id = Ecto.UUID.generate()
      assert Notes.linked_characters(scope, invalid_note_id) == []
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
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "link_faction/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.link_faction(scope, invalid_note_id, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      assert {:error, :faction_not_found} = Notes.link_faction(scope, note.id, invalid_faction_id)
    end

    test "link_faction/3 with cross-scope note returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      faction = faction_fixture(scope2)

      # Note exists in scope1, faction is in scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} = Notes.link_faction(scope1, note.id, faction.id)
    end

    test "link_faction/3 with cross-scope faction returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      faction = faction_fixture(scope1)

      # Note is in scope1, faction is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_faction(scope2, note.id, faction.id)
    end

    test "link_faction/3 prevents duplicate links" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_faction(scope, note.id, faction.id)
    end

    test "unlink_faction/3 successfully removes a note-faction link" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)

      {:ok, _link} = Notes.link_faction(scope, note.id, faction.id)
      assert Notes.faction_linked?(scope, note.id, faction.id)

      assert {:ok, _link} = Notes.unlink_faction(scope, note.id, faction.id)
      refute Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "unlink_faction/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)

      assert {:error, :not_found} = Notes.unlink_faction(scope, note.id, faction.id)
    end

    test "unlink_faction/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Notes.unlink_faction(scope, invalid_note_id, faction.id)
    end

    test "unlink_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Notes.unlink_faction(scope, note.id, invalid_faction_id)
    end

    test "faction_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)

      refute Notes.faction_linked?(scope, note.id, faction.id)
    end

    test "faction_linked?/3 with invalid note_id returns false" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      refute Notes.faction_linked?(scope, invalid_note_id, faction.id)
    end

    test "faction_linked?/3 with invalid faction_id returns false" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      refute Notes.faction_linked?(scope, note.id, invalid_faction_id)
    end

    test "linked_factions/2 returns all factions linked to a note" do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)
      unlinked_faction = faction_fixture(scope)

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
      scope = user_scope_fixture()
      note = note_fixture(scope)

      assert Notes.linked_factions(scope, note.id) == []
    end

    test "linked_factions/2 with invalid note_id returns empty list" do
      scope = user_scope_fixture()

      invalid_note_id = Ecto.UUID.generate()
      assert Notes.linked_factions(scope, invalid_note_id) == []
    end

    test "linked_factions/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      note = note_fixture(scope1)
      faction = faction_fixture(scope1)

      {:ok, _} = Notes.link_faction(scope1, note.id, faction.id)

      # Same note ID in different scope should return empty
      assert Notes.linked_factions(scope2, note.id) == []
    end
  end

  describe "note - quest links" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "link_quest/3 successfully links a note and quest" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "link_quest/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

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
      quest = quest_fixture(scope2)

      # Note exists in scope1, quest is in scope2, so quest_not_found is returned first
      assert {:error, :quest_not_found} = Notes.link_quest(scope1, note.id, quest.id)
    end

    test "link_quest/3 with cross-scope quest returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      note = note_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1)

      # Note is in scope1, quest is in scope1, but called with scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Notes.link_quest(scope2, note.id, quest.id)
    end

    test "link_quest/3 prevents duplicate links" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert {:error, %Ecto.Changeset{}} = Notes.link_quest(scope, note.id, quest.id)
    end

    test "unlink_quest/3 successfully removes a note-quest link" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      {:ok, _link} = Notes.link_quest(scope, note.id, quest.id)
      assert Notes.quest_linked?(scope, note.id, quest.id)

      assert {:ok, _link} = Notes.unlink_quest(scope, note.id, quest.id)
      refute Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "unlink_quest/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:error, :not_found} = Notes.unlink_quest(scope, note.id, quest.id)
    end

    test "unlink_quest/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

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
      quest = quest_fixture(scope)

      refute Notes.quest_linked?(scope, note.id, quest.id)
    end

    test "quest_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

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
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)
      unlinked_quest = quest_fixture(scope)

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
      quest = quest_fixture(scope1)

      {:ok, _} = Notes.link_quest(scope1, note.id, quest.id)

      # Same note ID in different scope should return empty
      assert Notes.linked_quests(scope2, note.id) == []
    end
  end

  describe "note parent relationships" do
    alias GameMasterCore.Notes.Note

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.LocationsFixtures

    test "create_note/2 with valid note parent creates hierarchical relationship" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      parent_note = note_fixture(scope, %{game_id: game.id, name: "Parent Note"})

      valid_attrs = %{
        name: "Child Note",
        content: "some content",
        game_id: game.id,
        parent_id: parent_note.id
      }

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.parent_id == parent_note.id
      # Backward compatibility: nil means Note parent
      assert note.parent_type == nil
    end

    test "create_note/2 with valid character parent creates polymorphic relationship" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      character = character_fixture(scope, %{game_id: game.id})

      valid_attrs = %{
        name: "Character Note",
        content: "some content",
        game_id: game.id,
        parent_id: character.id,
        parent_type: "character"
      }

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.parent_id == character.id
      assert note.parent_type == "character"
    end

    test "create_note/2 with valid quest parent creates polymorphic relationship" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      valid_attrs = %{
        name: "Quest Note",
        content: "some content",
        parent_id: quest.id,
        parent_type: "quest"
      }

      assert {:ok, %Note{} = note} = Notes.create_note_for_game(scope, valid_attrs)
      assert note.parent_id == quest.id
      assert note.parent_type == "quest"
    end

    test "create_note/2 with valid location parent creates polymorphic relationship" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      location = location_fixture(scope, %{game_id: game.id})

      valid_attrs = %{
        name: "Location Note",
        content: "some content",
        game_id: game.id,
        parent_id: location.id,
        parent_type: "location"
      }

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.parent_id == location.id
      assert note.parent_type == "location"
    end

    test "create_note/2 with valid faction parent creates polymorphic relationship" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      faction = faction_fixture(scope, %{game_id: game.id})

      valid_attrs = %{
        name: "Faction Note",
        content: "some content",
        game_id: game.id,
        parent_id: faction.id,
        parent_type: "faction"
      }

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.parent_id == faction.id
      assert note.parent_type == "faction"
    end

    test "create_note/2 with parent_type but no parent_id returns error" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      invalid_attrs = %{
        name: "Invalid Note",
        content: "some content",
        game_id: game.id,
        parent_type: "character"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Notes.create_note(scope, invalid_attrs)
      assert "cannot set parent_type without parent_id" in errors_on(changeset).parent_type
    end

    test "create_note/2 with invalid parent_type returns error" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      invalid_attrs = %{
        name: "Invalid Note",
        content: "some content",
        game_id: game.id,
        parent_id: Ecto.UUID.generate(),
        parent_type: "InvalidType"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Notes.create_note(scope, invalid_attrs)

      assert "must be one of: character, quest, location, faction" in errors_on(changeset).parent_type
    end

    test "create_note/2 with non-existent character parent returns error" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      invalid_attrs = %{
        name: "Invalid Note",
        content: "some content",
        game_id: game.id,
        parent_id: Ecto.UUID.generate(),
        parent_type: "character"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Notes.create_note(scope, invalid_attrs)

      assert "parent character does not exist or does not belong to the same game" in errors_on(
               changeset
             ).parent_id
    end

    test "create_note/2 with cross-game character parent returns error" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      game = game_fixture(scope)
      other_game = game_fixture(other_scope)
      character = character_fixture(other_scope, %{game_id: other_game.id})

      invalid_attrs = %{
        name: "Invalid Note",
        content: "some content",
        game_id: game.id,
        parent_id: character.id,
        parent_type: "character"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Notes.create_note(scope, invalid_attrs)

      assert "parent character does not exist or does not belong to the same game" in errors_on(
               changeset
             ).parent_id
    end

    test "create_note/2 with self-referencing parent returns error" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      note = note_fixture(scope, %{game_id: game.id})

      update_attrs = %{parent_id: note.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Notes.update_note(scope, note, update_attrs)

      assert "note cannot be its own parent" in errors_on(changeset).parent_id
    end

    test "update_note/3 can add polymorphic parent to existing note" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      note = note_fixture(scope, %{game_id: game.id})
      character = character_fixture(scope, %{game_id: game.id})

      update_attrs = %{parent_id: character.id, parent_type: "character"}

      assert {:ok, %Note{} = updated_note} = Notes.update_note(scope, note, update_attrs)
      assert updated_note.parent_id == character.id
      assert updated_note.parent_type == "character"
    end

    test "update_note/3 can remove polymorphic parent" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      character = character_fixture(scope, %{game_id: game.id})

      note =
        note_fixture(scope, %{
          game_id: game.id,
          parent_id: character.id,
          parent_type: "character"
        })

      update_attrs = %{parent_id: nil, parent_type: nil}

      assert {:ok, %Note{} = updated_note} = Notes.update_note(scope, note, update_attrs)
      assert updated_note.parent_id == nil
      assert updated_note.parent_type == nil
    end

    test "backward compatibility: existing parent_id without parent_type works" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      parent_note = note_fixture(scope, %{game_id: game.id, name: "Parent Note"})

      # Simulate existing data where parent_type is nil but parent_id exists (note hierarchy)
      valid_attrs = %{
        name: "Child Note",
        content: "some content",
        game_id: game.id,
        parent_id: parent_note.id
        # parent_type intentionally omitted (nil)
      }

      assert {:ok, %Note{} = note} = Notes.create_note(scope, valid_attrs)
      assert note.parent_id == parent_note.id
      # Backward compatibility maintained
      assert note.parent_type == nil
    end
  end

  describe "character notes tree" do
    alias GameMasterCore.Notes.Note
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.CharactersFixtures

    test "list_character_notes_tree_for_game/2 returns empty list for character with no notes" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      assert Notes.list_character_notes_tree_for_game(scope, character.id) == []
    end

    test "list_character_notes_tree_for_game/2 returns direct child notes" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      _note1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character Note 1",
          parent_id: character.id,
          parent_type: "character"
        })

      _note2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character Note 2",
          parent_id: character.id,
          parent_type: "character"
        })

      tree = Notes.list_character_notes_tree_for_game(scope, character.id)

      assert length(tree) == 2
      note_names = Enum.map(tree, & &1.name) |> Enum.sort()
      assert note_names == ["Character Note 1", "Character Note 2"]

      # Check that all notes have empty children lists initially
      assert Enum.all?(tree, fn note -> Map.get(note, :children) == [] end)
    end

    test "list_character_notes_tree_for_game/2 builds hierarchical structure with traditional note parents" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      # Create root note attached to character
      root_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Root Note",
          parent_id: character.id,
          parent_type: "character"
        })

      # Create child note (traditional note hierarchy)
      child_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child Note",
          parent_id: root_note.id
          # parent_type is nil for traditional note hierarchy
        })

      # Create grandchild note
      grandchild_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Grandchild Note",
          parent_id: child_note.id
        })

      tree = Notes.list_character_notes_tree_for_game(scope, character.id)

      assert length(tree) == 1
      root = hd(tree)
      assert root.name == "Root Note"
      assert root.id == root_note.id

      # Check children structure
      assert length(Map.get(root, :children)) == 1
      child = hd(Map.get(root, :children))
      assert child.name == "Child Note"
      assert child.id == child_note.id

      # Check grandchildren structure  
      assert length(Map.get(child, :children)) == 1
      grandchild = hd(Map.get(child, :children))
      assert grandchild.name == "Grandchild Note"
      assert grandchild.id == grandchild_note.id
      assert Map.get(grandchild, :children) == []
    end

    test "list_character_notes_tree_for_game/2 excludes notes from other characters" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character1 = character_fixture(scope, %{game_id: game.id})
      character2 = character_fixture(scope, %{game_id: game.id})

      # Note for character1
      _note1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character 1 Note",
          parent_id: character1.id,
          parent_type: "character"
        })

      # Note for character2
      _note2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Character 2 Note",
          parent_id: character2.id,
          parent_type: "character"
        })

      tree1 = Notes.list_character_notes_tree_for_game(scope, character1.id)
      tree2 = Notes.list_character_notes_tree_for_game(scope, character2.id)

      assert length(tree1) == 1
      assert length(tree2) == 1
      assert hd(tree1).name == "Character 1 Note"
      assert hd(tree2).name == "Character 2 Note"
    end

    test "list_character_notes_tree_for_game/2 excludes notes from other games" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      game1 = game_fixture(scope1)
      game2 = game_fixture(scope2)
      scope1 = Scope.put_game(scope1, game1)
      scope2 = Scope.put_game(scope2, game2)
      character1 = character_fixture(scope1, %{game_id: game1.id})
      character2 = character_fixture(scope2, %{game_id: game2.id})

      # Note in game1
      _note1 =
        note_fixture(scope1, %{
          game_id: game1.id,
          name: "Game 1 Note",
          parent_id: character1.id,
          parent_type: "character"
        })

      # Note in game2  
      _note2 =
        note_fixture(scope2, %{
          game_id: game2.id,
          name: "Game 2 Note",
          parent_id: character2.id,
          parent_type: "character"
        })

      # Use different scopes to access different games
      tree1 = Notes.list_character_notes_tree_for_game(scope1, character1.id)
      tree2 = Notes.list_character_notes_tree_for_game(scope2, character2.id)

      assert length(tree1) == 1
      assert length(tree2) == 1
      assert hd(tree1).name == "Game 1 Note"
      assert hd(tree2).name == "Game 2 Note"
    end

    test "list_character_notes_tree_for_game/2 orders notes alphabetically" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      _note_z =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Z Note",
          parent_id: character.id,
          parent_type: "character"
        })

      _note_a =
        note_fixture(scope, %{
          game_id: game.id,
          name: "A Note",
          parent_id: character.id,
          parent_type: "character"
        })

      _note_m =
        note_fixture(scope, %{
          game_id: game.id,
          name: "M Note",
          parent_id: character.id,
          parent_type: "character"
        })

      tree = Notes.list_character_notes_tree_for_game(scope, character.id)

      assert length(tree) == 3
      note_names = Enum.map(tree, & &1.name)
      assert note_names == ["A Note", "M Note", "Z Note"]
    end

    test "list_character_notes_tree_for_game/2 handles complex mixed hierarchies" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      # Create multiple root notes
      root1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Root 1",
          parent_id: character.id,
          parent_type: "character"
        })

      root2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Root 2",
          parent_id: character.id,
          parent_type: "character"
        })

      # Root 1 children
      child1_1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child 1.1",
          parent_id: root1.id
        })

      _child1_2 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child 1.2",
          parent_id: root1.id
        })

      # Root 2 children
      _child2_1 =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child 2.1",
          parent_id: root2.id
        })

      # Grandchild under child1_1
      _grandchild =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Grandchild 1.1.1",
          parent_id: child1_1.id
        })

      tree = Notes.list_character_notes_tree_for_game(scope, character.id)

      assert length(tree) == 2

      # Find the roots by name
      root1_result = Enum.find(tree, &(&1.name == "Root 1"))
      root2_result = Enum.find(tree, &(&1.name == "Root 2"))

      assert root1_result != nil
      assert root2_result != nil

      # Check Root 1 structure
      root1_children = Map.get(root1_result, :children)
      assert length(root1_children) == 2
      child_names = Enum.map(root1_children, & &1.name) |> Enum.sort()
      assert child_names == ["Child 1.1", "Child 1.2"]

      # Check Root 2 structure
      root2_children = Map.get(root2_result, :children)
      assert length(root2_children) == 1
      assert hd(root2_children).name == "Child 2.1"

      # Check grandchild under Child 1.1
      child1_1_result = Enum.find(root1_children, &(&1.name == "Child 1.1"))
      grandchildren = Map.get(child1_1_result, :children)
      assert length(grandchildren) == 1
      assert hd(grandchildren).name == "Grandchild 1.1.1"
    end

    test "list_character_notes_tree_for_game/2 includes entity_type field for all nodes" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = Scope.put_game(scope, game)
      character = character_fixture(scope, %{game_id: game.id})

      # Create parent note attached to character
      parent_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Parent Note",
          parent_id: character.id,
          parent_type: "character"
        })

      # Create child note under the parent note
      _child_note =
        note_fixture(scope, %{
          game_id: game.id,
          name: "Child Note",
          parent_id: parent_note.id
        })

      tree = Notes.list_character_notes_tree_for_game(scope, character.id)
      [parent_node] = tree
      [child_node] = Map.get(parent_node, :children)

      # Verify entity_type field is present on all nodes
      assert parent_node.entity_type == "note"
      assert child_node.entity_type == "note"
    end
  end
end
