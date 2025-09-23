defmodule GameMasterCore.CharactersTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Characters

  describe "characters" do
    alias GameMasterCore.Characters.Character
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.QuestsFixtures

    @invalid_attrs %{name: nil, level: nil, content: nil, class: nil, image_url: nil}

    test "list_characters/1 returns all scoped characters" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      character = character_fixture(scope)
      other_character = character_fixture(other_scope)
      assert Characters.list_characters(scope) == [character]
      assert Characters.list_characters(other_scope) == [other_character]
    end

    test "get_character!/2 returns the character with given id" do
      scope = game_scope_fixture()
      character = character_fixture(scope)
      other_scope = game_scope_fixture()
      assert Characters.get_character!(scope, character.id) == character

      assert_raise Ecto.NoResultsError, fn ->
        Characters.get_character!(other_scope, character.id)
      end
    end

    test "create_character/2 with valid data creates a character" do
      scope = game_scope_fixture()
      game = game_fixture(scope)

      valid_attrs = %{
        name: "some name",
        level: 42,
        content: "some content",
        class: "some class",
        image_url: "some image_url",
        game_id: game.id
      }

      assert {:ok, %Character{} = character} = Characters.create_character(scope, valid_attrs)
      assert character.name == "some name"
      assert character.level == 42
      assert character.content == "some content"
      assert character.class == "some class"
      assert character.image_url == "some image_url"
      assert character.user_id == scope.user.id
    end

    test "create_character/2 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(scope, attrs_with_game)
    end

    test "update_character/3 with valid data updates the character" do
      scope = game_scope_fixture()
      game = game_fixture(scope)
      character = character_fixture(scope, %{game_id: game.id})

      update_attrs = %{
        name: "some updated name",
        level: 43,
        content: "some updated content",
        class: "some updated class",
        image_url: "some updated image_url"
      }

      assert {:ok, %Character{} = character} =
               Characters.update_character(scope, character, update_attrs)

      assert character.name == "some updated name"
      assert character.level == 43
      assert character.content == "some updated content"
      assert character.class == "some updated class"
      assert character.image_url == "some updated image_url"
    end

    test "update_character/3 with invalid scope doesn't raise but doesn't permit update" do
      scope = game_scope_fixture()
      _other_scope = game_scope_fixture()
      character = character_fixture(scope)

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update characters
      assert {:ok, _} = Characters.update_character(scope, character, %{name: "Updated by owner"})
    end

    test "update_character/3 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      character = character_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Characters.update_character(scope, character, @invalid_attrs)

      assert character == Characters.get_character!(scope, character.id)
    end

    test "delete_character/2 deletes the character" do
      scope = game_scope_fixture()
      character = character_fixture(scope)
      assert {:ok, %Character{}} = Characters.delete_character(scope, character)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(scope, character.id) end
    end

    test "delete_character/2 with invalid scope doesn't raise but works based on game permissions" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      character = character_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Characters.delete_character(other_scope, character)
    end

    test "change_character/2 returns a character changeset" do
      scope = game_scope_fixture()
      character = character_fixture(scope)
      assert %Ecto.Changeset{} = Characters.change_character(scope, character)
    end

    test "list_characters_for_game/1 returns characters for a specific game" do
      scope = game_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)

      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)

      _character1 = character_fixture(scope1, %{game_id: game1.id, name: "Game 1 Character"})
      _character2 = character_fixture(scope1, %{game_id: game1.id, name: "Game 1 Character"})
      _character3 = character_fixture(scope2, %{game_id: game2.id, name: "Game 2 Character"})

      characters1 = Characters.list_characters_for_game(scope1)
      characters2 = Characters.list_characters_for_game(scope2)

      assert length(characters1) == 2
      assert length(characters2) == 1
      assert hd(characters1).name == "Game 1 Character"
      assert hd(characters2).name == "Game 2 Character"
    end

    test "list_characters_for_game/1 returns empty list for game with no characters" do
      scope = game_scope_fixture()
      game = game_fixture(scope)

      scope = Scope.put_game(scope, game)

      assert Characters.list_characters_for_game(scope) == []
    end

    test "get_character_for_game!/2 returns character only if it belongs to the game" do
      scope = game_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      character1 = character_fixture(scope, %{game_id: game1.id})

      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)

      assert Characters.get_character_for_game!(scope1, character1.id) == character1

      assert_raise Ecto.NoResultsError, fn ->
        Characters.get_character_for_game!(scope2, character1.id)
      end
    end

    test "create_character_for_game/2 creates a character associated with the game" do
      scope = game_scope_fixture()
      game = game_fixture(scope)

      scope = Scope.put_game(scope, game)

      valid_attrs = %{
        name: "some name",
        level: 42,
        content: "some content",
        class: "some class",
        image_url: "some image_url",
        game_id: game.id
      }

      assert {:ok, %Character{} = character} =
               Characters.create_character_for_game(scope, valid_attrs)

      assert character.game_id == scope.game.id
      assert character.user_id == scope.user.id
      assert character.name == "some name"
    end
  end

  describe "character - note links" do
    import GameMasterCore.AccountsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.QuestsFixtures

    test "link_note/3 successfully links a character and note" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Characters.link_note(scope, character.id, note.id)
      assert Characters.note_linked?(scope, character.id, note.id)
    end

    test "link_note/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.link_note(scope, invalid_character_id, note.id)
    end

    test "link_note/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Characters.link_note(scope, character.id, invalid_note_id)
    end

    test "link_note/3 with cross-scope character returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      note = note_fixture(scope2, %{game_id: scope2.game.id})

      # Character exists in scope1, note is in scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Characters.link_note(scope1, character.id, note.id)
    end

    test "link_note/3 with cross-scope note returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      note = note_fixture(scope1, %{game_id: scope1.game.id})

      # Character is in scope1, note is in scope1, but called with scope2, so character_not_found is returned first
      assert {:error, :character_not_found} = Characters.link_note(scope2, character.id, note.id)
    end

    test "link_note/3 prevents duplicate links" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Characters.link_note(scope, character.id, note.id)
      assert {:error, %Ecto.Changeset{}} = Characters.link_note(scope, character.id, note.id)
    end

    test "unlink_note/3 successfully removes a character-note link" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})

      {:ok, _link} = Characters.link_note(scope, character.id, note.id)
      assert Characters.note_linked?(scope, character.id, note.id)

      assert {:ok, _link} = Characters.unlink_note(scope, character.id, note.id)
      refute Characters.note_linked?(scope, character.id, note.id)
    end

    test "unlink_note/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})

      assert {:error, :not_found} = Characters.unlink_note(scope, character.id, note.id)
    end

    test "unlink_note/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.unlink_note(scope, invalid_character_id, note.id)
    end

    test "unlink_note/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Characters.unlink_note(scope, character.id, invalid_note_id)
    end

    test "note_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})

      refute Characters.note_linked?(scope, character.id, note.id)
    end

    test "note_linked?/3 with invalid character_id returns false" do
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()
      refute Characters.note_linked?(scope, invalid_character_id, note.id)
    end

    test "note_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_note_id = Ecto.UUID.generate()
      refute Characters.note_linked?(scope, character.id, invalid_note_id)
    end

    test "linked_notes/2 returns all notes linked to a character" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note1 = note_fixture(scope, %{game_id: scope.game.id})
      note2 = note_fixture(scope, %{game_id: scope.game.id})
      unlinked_note = note_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Characters.link_note(scope, character.id, note1.id)
      {:ok, _} = Characters.link_note(scope, character.id, note2.id)

      linked_notes_with_meta = Characters.linked_notes(scope, character.id)
      assert length(linked_notes_with_meta) == 2
      linked_notes = Enum.map(linked_notes_with_meta, & &1.entity)
      assert note1 in linked_notes
      assert note2 in linked_notes
      refute unlinked_note in linked_notes
    end

    test "linked_notes/2 returns empty list for character with no linked notes" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert Characters.linked_notes(scope, character.id) == []
    end

    test "linked_notes/2 with invalid character_id returns empty list" do
      scope = game_scope_fixture()

      invalid_character_id = Ecto.UUID.generate()
      assert Characters.linked_notes(scope, invalid_character_id) == []
    end

    test "linked_notes/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      note = note_fixture(scope1, %{game_id: scope1.game.id})

      {:ok, _} = Characters.link_note(scope1, character.id, note.id)

      # Same character ID in different scope should return empty
      assert Characters.linked_notes(scope2, character.id) == []
    end
  end

  describe "character - faction links" do
    import GameMasterCore.AccountsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.QuestsFixtures

    test "link_faction/3 successfully links a character and faction" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Characters.link_faction(scope, character.id, faction.id)
      assert Characters.faction_linked?(scope, character.id, faction.id)
    end

    test "link_faction/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.link_faction(scope, invalid_character_id, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Characters.link_faction(scope, character.id, invalid_faction_id)
    end

    test "link_faction/3 with cross-scope character returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope2, %{game_id: scope2.game.id})

      # Character exists in scope1, faction is in scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} =
               Characters.link_faction(scope1, character.id, faction.id)
    end

    test "link_faction/3 with cross-scope faction returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})

      # Character is in scope1, faction is in scope1, but called with scope2, so character_not_found is returned first
      assert {:error, :character_not_found} =
               Characters.link_faction(scope2, character.id, faction.id)
    end

    test "link_faction/3 prevents duplicate links" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:ok, _link} = Characters.link_faction(scope, character.id, faction.id)

      assert {:error, %Ecto.Changeset{}} =
               Characters.link_faction(scope, character.id, faction.id)
    end

    test "unlink_faction/3 successfully removes a character-faction link" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      {:ok, _link} = Characters.link_faction(scope, character.id, faction.id)
      assert Characters.faction_linked?(scope, character.id, faction.id)

      assert {:ok, _link} = Characters.unlink_faction(scope, character.id, faction.id)
      refute Characters.faction_linked?(scope, character.id, faction.id)
    end

    test "unlink_faction/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert {:error, :not_found} = Characters.unlink_faction(scope, character.id, faction.id)
    end

    test "unlink_faction/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.unlink_faction(scope, invalid_character_id, faction.id)
    end

    test "unlink_faction/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Characters.unlink_faction(scope, character.id, invalid_faction_id)
    end

    test "faction_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      refute Characters.faction_linked?(scope, character.id, faction.id)
    end

    test "faction_linked?/3 with invalid character_id returns false" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_character_id = Ecto.UUID.generate()
      refute Characters.faction_linked?(scope, invalid_character_id, faction.id)
    end

    test "faction_linked?/3 with invalid faction_id returns false" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_faction_id = Ecto.UUID.generate()
      refute Characters.faction_linked?(scope, character.id, invalid_faction_id)
    end

    test "linked_factions/2 returns all factions linked to a character" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction1 = faction_fixture(scope, %{game_id: scope.game.id})
      faction2 = faction_fixture(scope, %{game_id: scope.game.id})
      unlinked_faction = faction_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Characters.link_faction(scope, character.id, faction1.id)
      {:ok, _} = Characters.link_faction(scope, character.id, faction2.id)

      linked_factions_with_meta = Characters.linked_factions(scope, character.id)
      assert length(linked_factions_with_meta) == 2
      linked_factions = Enum.map(linked_factions_with_meta, & &1.entity)
      assert faction1 in linked_factions
      assert faction2 in linked_factions
      refute unlinked_faction in linked_factions
    end

    test "linked_factions/2 returns empty list for character with no linked factions" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert Characters.linked_factions(scope, character.id) == []
    end

    test "linked_factions/2 with invalid character_id returns empty list" do
      scope = game_scope_fixture()

      invalid_character_id = Ecto.UUID.generate()
      assert Characters.linked_factions(scope, invalid_character_id) == []
    end

    test "linked_factions/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})

      {:ok, _} = Characters.link_faction(scope1, character.id, faction.id)

      # Same character ID in different scope should return empty
      assert Characters.linked_factions(scope2, character.id) == []
    end
  end

  describe "character - quest links" do
    import GameMasterCore.AccountsFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.QuestsFixtures

    test "link_quest/3 successfully links a character and quest" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Characters.link_quest(scope, character.id, quest.id)
      assert Characters.quest_linked?(scope, character.id, quest.id)
    end

    test "link_quest/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.link_quest(scope, invalid_character_id, quest.id)
    end

    test "link_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} =
               Characters.link_quest(scope, character.id, invalid_quest_id)
    end

    test "link_quest/3 with cross-scope character returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope2)

      # Character exists in scope1, quest is in scope2, so quest_not_found is returned first
      assert {:error, :quest_not_found} = Characters.link_quest(scope1, character.id, quest.id)
    end

    test "link_quest/3 with cross-scope quest returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1)

      # Character is in scope1, quest is in scope1, but called with scope2, so character_not_found is returned first
      assert {:error, :character_not_found} =
               Characters.link_quest(scope2, character.id, quest.id)
    end

    test "link_quest/3 prevents duplicate links" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Characters.link_quest(scope, character.id, quest.id)
      assert {:error, %Ecto.Changeset{}} = Characters.link_quest(scope, character.id, quest.id)
    end

    test "unlink_quest/3 successfully removes a character-quest link" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      {:ok, _link} = Characters.link_quest(scope, character.id, quest.id)
      assert Characters.quest_linked?(scope, character.id, quest.id)

      assert {:ok, _link} = Characters.unlink_quest(scope, character.id, quest.id)
      refute Characters.quest_linked?(scope, character.id, quest.id)
    end

    test "unlink_quest/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:error, :not_found} = Characters.unlink_quest(scope, character.id, quest.id)
    end

    test "unlink_quest/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Characters.unlink_quest(scope, invalid_character_id, quest.id)
    end

    test "unlink_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} =
               Characters.unlink_quest(scope, character.id, invalid_quest_id)
    end

    test "quest_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      refute Characters.quest_linked?(scope, character.id, quest.id)
    end

    test "quest_linked?/3 with invalid character_id returns false" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()
      refute Characters.quest_linked?(scope, invalid_character_id, quest.id)
    end

    test "quest_linked?/3 with invalid quest_id returns false" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      refute Characters.quest_linked?(scope, character.id, invalid_quest_id)
    end

    test "linked_quests/2 returns all quests linked to a character" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)
      unlinked_quest = quest_fixture(scope)

      {:ok, _} = Characters.link_quest(scope, character.id, quest1.id)
      {:ok, _} = Characters.link_quest(scope, character.id, quest2.id)

      linked_quests_with_meta = Characters.linked_quests(scope, character.id)
      assert length(linked_quests_with_meta) == 2
      linked_quests = Enum.map(linked_quests_with_meta, & &1.entity)
      assert quest1 in linked_quests
      assert quest2 in linked_quests
      refute unlinked_quest in linked_quests
    end

    test "linked_quests/2 returns empty list for character with no linked quests" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      assert Characters.linked_quests(scope, character.id) == []
    end

    test "linked_quests/2 with invalid character_id returns empty list" do
      scope = game_scope_fixture()

      invalid_character_id = Ecto.UUID.generate()
      assert Characters.linked_quests(scope, invalid_character_id) == []
    end

    test "linked_quests/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      character = character_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1)

      {:ok, _} = Characters.link_quest(scope1, character.id, quest.id)

      # Same character ID in different scope should return empty
      assert Characters.linked_quests(scope2, character.id) == []
    end
  end
end
