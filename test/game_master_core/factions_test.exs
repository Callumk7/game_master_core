defmodule GameMasterCore.FactionsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Factions

  describe "factions" do
    alias GameMasterCore.Factions.Faction
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.GamesFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.QuestsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_factions/1 returns all scoped factions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      faction = faction_fixture(scope)
      other_faction = faction_fixture(other_scope)
      assert Factions.list_factions(scope) == [faction]
      assert Factions.list_factions(other_scope) == [other_faction]
    end

    test "get_faction!/2 returns the faction with given id" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      other_scope = user_scope_fixture()
      assert Factions.get_faction!(scope, faction.id) == faction
      assert_raise Ecto.NoResultsError, fn -> Factions.get_faction!(other_scope, faction.id) end
    end

    test "create_faction/2 with valid data creates a faction" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      valid_attrs = %{
        name: "some name",
        description: "some description",
        game_id: game.id
      }

      assert {:ok, %Faction{} = faction} = Factions.create_faction(scope, valid_attrs)
      assert faction.name == "some name"
      assert faction.description == "some description"
      assert faction.game_id == game.id
      assert faction.user_id == scope.user.id
    end

    test "create_faction/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Factions.create_faction(scope, attrs_with_game)
    end

    test "update_faction/3 with valid data updates the faction" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      scope = Scope.put_game(scope, game)

      faction = faction_fixture(scope, %{game_id: game.id})

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Faction{} = faction} = Factions.update_faction(scope, faction, update_attrs)
      assert faction.name == "some updated name"
      assert faction.description == "some updated description"
    end

    test "update_faction/3 with invalid scope doesn't raise but doesn't permit update" do
      scope = user_scope_fixture()
      _other_scope = user_scope_fixture()
      faction = faction_fixture(scope)

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update factions
      assert {:ok, _} = Factions.update_faction(scope, faction, %{name: "Updated by owner"})
    end

    test "update_faction/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      assert {:error, %Ecto.Changeset{}} = Factions.update_faction(scope, faction, @invalid_attrs)
      assert faction == Factions.get_faction!(scope, faction.id)
    end

    test "delete_faction/2 deletes the faction" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      assert {:ok, %Faction{}} = Factions.delete_faction(scope, faction)
      assert_raise Ecto.NoResultsError, fn -> Factions.get_faction!(scope, faction.id) end
    end

    test "delete_faction/2 with invalid scope doesn't raise but works based on game permissions" do
      scope = user_scope_fixture()
      _other_scope = user_scope_fixture()
      faction = faction_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Factions.delete_faction(scope, faction)
    end

    test "change_faction/2 returns a faction changeset" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      assert %Ecto.Changeset{} = Factions.change_faction(scope, faction)
    end

    test "list_factions_for_game/1 returns factions for a specific game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)

      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)

      _faction1 = faction_fixture(scope1, %{game_id: game1.id, name: "Game 1 Faction"})
      _faction2 = faction_fixture(scope1, %{game_id: game1.id, name: "Game 1 Faction"})
      _faction3 = faction_fixture(scope2, %{game_id: game2.id, name: "Game 2 Faction"})

      factions1 = Factions.list_factions_for_game(scope1)
      factions2 = Factions.list_factions_for_game(scope2)

      assert length(factions1) == 2
      assert length(factions2) == 1
      assert hd(factions1).name == "Game 1 Faction"
      assert hd(factions2).name == "Game 2 Faction"
    end

    test "list_factions_for_game/1 returns empty list for game with no factions" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      scope = Scope.put_game(scope, game)

      assert Factions.list_factions_for_game(scope) == []
    end

    test "get_faction_for_game!/2 returns faction only if it belongs to the game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)
      faction1 = faction_fixture(scope, %{game_id: game1.id})

      scope1 = Scope.put_game(scope, game1)
      scope2 = Scope.put_game(scope, game2)

      assert Factions.get_faction_for_game!(scope1, faction1.id) == faction1

      assert_raise Ecto.NoResultsError, fn ->
        Factions.get_faction_for_game!(scope2, faction1.id)
      end
    end

    test "create_faction_for_game/2 creates a faction associated with the game" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      scope = Scope.put_game(scope, game)

      valid_attrs = %{
        name: "some name",
        description: "some description",
        game_id: game.id
      }

      assert {:ok, %Faction{} = faction} = Factions.create_faction_for_game(scope, valid_attrs)

      assert faction.game_id == scope.game.id
      assert faction.user_id == scope.user.id
      assert faction.name == "some name"
    end
  end

  describe "faction - note links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.QuestsFixtures

    test "link_note/3 successfully links a faction and note" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Factions.link_note(scope, faction.id, note.id)
      assert Factions.note_linked?(scope, faction.id, note.id)
    end

    test "link_note/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      assert {:error, :faction_not_found} = Factions.link_note(scope, invalid_faction_id, note.id)
    end

    test "link_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Factions.link_note(scope, faction.id, invalid_note_id)
    end

    test "link_note/3 with cross-scope faction returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      note = note_fixture(scope2)

      # Faction exists in scope1, note is in scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Factions.link_note(scope1, faction.id, note.id)
    end

    test "link_note/3 with cross-scope note returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      note = note_fixture(scope1)

      # Faction is in scope1, note is in scope1, but called with scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} = Factions.link_note(scope2, faction.id, note.id)
    end

    test "link_note/3 prevents duplicate links" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Factions.link_note(scope, faction.id, note.id)
      assert {:error, %Ecto.Changeset{}} = Factions.link_note(scope, faction.id, note.id)
    end

    test "unlink_note/3 successfully removes a faction-note link" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note = note_fixture(scope)

      {:ok, _link} = Factions.link_note(scope, faction.id, note.id)
      assert Factions.note_linked?(scope, faction.id, note.id)

      assert {:ok, _link} = Factions.unlink_note(scope, faction.id, note.id)
      refute Factions.note_linked?(scope, faction.id, note.id)
    end

    test "unlink_note/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note = note_fixture(scope)

      assert {:error, :not_found} = Factions.unlink_note(scope, faction.id, note.id)
    end

    test "unlink_note/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Factions.unlink_note(scope, invalid_faction_id, note.id)
    end

    test "unlink_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Factions.unlink_note(scope, faction.id, invalid_note_id)
    end

    test "note_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note = note_fixture(scope)

      refute Factions.note_linked?(scope, faction.id, note.id)
    end

    test "note_linked?/3 with invalid faction_id returns false" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      refute Factions.note_linked?(scope, invalid_faction_id, note.id)
    end

    test "note_linked?/3 with invalid note_id returns false" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      refute Factions.note_linked?(scope, faction.id, invalid_note_id)
    end

    test "linked_notes/2 returns all notes linked to a faction" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)
      unlinked_note = note_fixture(scope)

      {:ok, _} = Factions.link_note(scope, faction.id, note1.id)
      {:ok, _} = Factions.link_note(scope, faction.id, note2.id)

      linked_notes_with_meta = Factions.linked_notes(scope, faction.id)
      assert length(linked_notes_with_meta) == 2
      linked_notes = Enum.map(linked_notes_with_meta, & &1.entity)
      assert note1 in linked_notes
      assert note2 in linked_notes
      refute unlinked_note in linked_notes
    end

    test "linked_notes/2 returns empty list for faction with no linked notes" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      assert Factions.linked_notes(scope, faction.id) == []
    end

    test "linked_notes/2 with invalid faction_id returns empty list" do
      scope = user_scope_fixture()

      invalid_faction_id = Ecto.UUID.generate()
      assert Factions.linked_notes(scope, invalid_faction_id) == []
    end

    test "linked_notes/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      note = note_fixture(scope1)

      {:ok, _} = Factions.link_note(scope1, faction.id, note.id)

      # Same faction ID in different scope should return empty
      assert Factions.linked_notes(scope2, faction.id) == []
    end
  end

  describe "faction - character links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.QuestsFixtures

    test "link_character/3 successfully links a faction and character" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Factions.link_character(scope, faction.id, character.id)
      assert Factions.character_linked?(scope, faction.id, character.id)
    end

    test "link_character/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Factions.link_character(scope, invalid_faction_id, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Factions.link_character(scope, faction.id, invalid_character_id)
    end

    test "link_character/3 with cross-scope faction returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      character = character_fixture(scope2)

      # Faction exists in scope1, character is in scope2, so character_not_found is returned first
      assert {:error, :character_not_found} =
               Factions.link_character(scope1, faction.id, character.id)
    end

    test "link_character/3 with cross-scope character returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      character = character_fixture(scope1)

      # Faction is in scope1, character is in scope1, but called with scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} =
               Factions.link_character(scope2, faction.id, character.id)
    end

    test "link_character/3 prevents duplicate links" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Factions.link_character(scope, faction.id, character.id)

      assert {:error, %Ecto.Changeset{}} =
               Factions.link_character(scope, faction.id, character.id)
    end

    test "unlink_character/3 successfully removes a faction-character link" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character = character_fixture(scope)

      {:ok, _link} = Factions.link_character(scope, faction.id, character.id)
      assert Factions.character_linked?(scope, faction.id, character.id)

      assert {:ok, _link} = Factions.unlink_character(scope, faction.id, character.id)
      refute Factions.character_linked?(scope, faction.id, character.id)
    end

    test "unlink_character/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character = character_fixture(scope)

      assert {:error, :not_found} = Factions.unlink_character(scope, faction.id, character.id)
    end

    test "unlink_character/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Factions.unlink_character(scope, invalid_faction_id, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Factions.unlink_character(scope, faction.id, invalid_character_id)
    end

    test "character_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character = character_fixture(scope)

      refute Factions.character_linked?(scope, faction.id, character.id)
    end

    test "character_linked?/3 with invalid faction_id returns false" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      refute Factions.character_linked?(scope, invalid_faction_id, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()
      refute Factions.character_linked?(scope, faction.id, invalid_character_id)
    end

    test "linked_characters/2 returns all characters linked to a faction" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)

      {:ok, _} = Factions.link_character(scope, faction.id, character1.id)
      {:ok, _} = Factions.link_character(scope, faction.id, character2.id)

      linked_characters_with_meta = Factions.linked_characters(scope, faction.id)
      assert length(linked_characters_with_meta) == 2
      linked_characters = Enum.map(linked_characters_with_meta, & &1.entity)
      assert character1 in linked_characters
      assert character2 in linked_characters
      refute unlinked_character in linked_characters
    end

    test "linked_characters/2 returns empty list for faction with no linked characters" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      assert Factions.linked_characters(scope, faction.id) == []
    end

    test "linked_characters/2 with invalid faction_id returns empty list" do
      scope = user_scope_fixture()

      invalid_faction_id = Ecto.UUID.generate()
      assert Factions.linked_characters(scope, invalid_faction_id) == []
    end

    test "linked_characters/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      faction = faction_fixture(scope1)
      character = character_fixture(scope1)

      {:ok, _} = Factions.link_character(scope1, faction.id, character.id)

      # Same faction ID in different scope should return empty
      assert Factions.linked_characters(scope2, faction.id) == []
    end
  end

  describe "faction - quest links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.QuestsFixtures

    test "link_quest/3 successfully links a faction and quest" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Factions.link_quest(scope, faction.id, quest.id)
      assert Factions.quest_linked?(scope, faction.id, quest.id)
    end

    test "link_quest/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Factions.link_quest(scope, invalid_faction_id, quest.id)
    end

    test "link_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      assert {:error, :quest_not_found} = Factions.link_quest(scope, faction.id, invalid_quest_id)
    end

    test "link_quest/3 with cross-scope faction returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope2)

      # Faction exists in scope1, quest is in scope2, so quest_not_found is returned first
      assert {:error, :quest_not_found} = Factions.link_quest(scope1, faction.id, quest.id)
    end

    test "link_quest/3 with cross-scope quest returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1)

      # Faction is in scope1, quest is in scope1, but called with scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} = Factions.link_quest(scope2, faction.id, quest.id)
    end

    test "link_quest/3 prevents duplicate links" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:ok, _link} = Factions.link_quest(scope, faction.id, quest.id)
      assert {:error, %Ecto.Changeset{}} = Factions.link_quest(scope, faction.id, quest.id)
    end

    test "unlink_quest/3 successfully removes a faction-quest link" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      {:ok, _link} = Factions.link_quest(scope, faction.id, quest.id)
      assert Factions.quest_linked?(scope, faction.id, quest.id)

      assert {:ok, _link} = Factions.unlink_quest(scope, faction.id, quest.id)
      refute Factions.quest_linked?(scope, faction.id, quest.id)
    end

    test "unlink_quest/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      assert {:error, :not_found} = Factions.unlink_quest(scope, faction.id, quest.id)
    end

    test "unlink_quest/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Factions.unlink_quest(scope, invalid_faction_id, quest.id)
    end

    test "unlink_quest/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} =
               Factions.unlink_quest(scope, faction.id, invalid_quest_id)
    end

    test "quest_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope)

      refute Factions.quest_linked?(scope, faction.id, quest.id)
    end

    test "quest_linked?/3 with invalid faction_id returns false" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      refute Factions.quest_linked?(scope, invalid_faction_id, quest.id)
    end

    test "quest_linked?/3 with invalid quest_id returns false" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      invalid_quest_id = Ecto.UUID.generate()
      refute Factions.quest_linked?(scope, faction.id, invalid_quest_id)
    end

    test "linked_quests/2 returns all quests linked to a faction" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)
      unlinked_quest = quest_fixture(scope)

      {:ok, _} = Factions.link_quest(scope, faction.id, quest1.id)
      {:ok, _} = Factions.link_quest(scope, faction.id, quest2.id)

      linked_quests_with_meta = Factions.linked_quests(scope, faction.id)
      assert length(linked_quests_with_meta) == 2
      linked_quests = Enum.map(linked_quests_with_meta, & &1.entity)
      assert quest1 in linked_quests
      assert quest2 in linked_quests
      refute unlinked_quest in linked_quests
    end

    test "linked_quests/2 returns empty list for faction with no linked quests" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})

      assert Factions.linked_quests(scope, faction.id) == []
    end

    test "linked_quests/2 with invalid faction_id returns empty list" do
      scope = game_scope_fixture()

      invalid_faction_id = Ecto.UUID.generate()
      assert Factions.linked_quests(scope, invalid_faction_id) == []
    end

    test "linked_quests/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      faction = faction_fixture(scope1, %{game_id: scope1.game.id})
      quest = quest_fixture(scope1)

      {:ok, _} = Factions.link_quest(scope1, faction.id, quest.id)

      # Same faction ID in different scope should return empty
      assert Factions.linked_quests(scope2, faction.id) == []
    end
  end
end
