defmodule GameMasterCore.QuestsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Quests

  describe "quests" do
    alias GameMasterCore.Quests.Quest

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.LocationsFixtures

    @invalid_attrs %{name: nil, content: nil}

    test "list_quests/1 returns all scoped quests" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(scope)
      other_quest = quest_fixture(other_scope)
      assert Quests.list_quests(scope) == [quest]
      assert Quests.list_quests(other_scope) == [other_quest]
    end

    test "get_quest!/2 returns the quest with given id" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      other_scope = game_scope_fixture()
      assert Quests.get_quest!(scope, quest.id) == quest
      assert_raise Ecto.NoResultsError, fn -> Quests.get_quest!(other_scope, quest.id) end
    end

    test "create_quest/2 with valid data creates a quest" do
      valid_attrs = %{name: "some name", content: "some content"}
      scope = game_scope_fixture()

      assert {:ok, %Quest{} = quest} = Quests.create_quest(scope, valid_attrs)
      assert quest.name == "some name"
      assert quest.content == "some content"
      assert quest.game_id == scope.game.id
    end

    test "create_quest/2 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Quests.create_quest(scope, @invalid_attrs)
    end

    test "update_quest/3 with valid data updates the quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      update_attrs = %{name: "some updated name", content: "some updated content"}

      assert {:ok, %Quest{} = quest} = Quests.update_quest(scope, quest, update_attrs)
      assert quest.name == "some updated name"
      assert quest.content == "some updated content"
    end

    test "update_quest/3 with invalid scope doesn't raise, but works based on game permissions" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert {:ok, _} = Quests.update_quest(other_scope, quest, %{})
    end

    test "update_quest/3 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Quests.update_quest(scope, quest, @invalid_attrs)
      assert quest == Quests.get_quest!(scope, quest.id)
    end

    test "delete_quest/2 deletes the quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      assert {:ok, %Quest{}} = Quests.delete_quest(scope, quest)
      assert_raise Ecto.NoResultsError, fn -> Quests.get_quest!(scope, quest.id) end
    end

    test "delete_quest/2 with invalid scope doesn't raise, but works based on game permissions" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(scope)
      assert {:ok, _} = Quests.delete_quest(other_scope, quest)
    end

    test "change_quest/2 returns a quest changeset" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      assert %Ecto.Changeset{} = Quests.change_quest(scope, quest)
    end
  end

  describe "quest - note links" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.LocationsFixtures

    test "link_note/3 successfully links a quest and note" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Quests.link_note(scope, quest.id, note.id)
      assert Quests.note_linked?(scope, quest.id, note.id)
    end

    test "link_note/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope)
      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} = Quests.link_note(scope, invalid_quest_id, note.id)
    end

    test "link_note/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} = Quests.link_note(scope, quest.id, invalid_note_id)
    end

    test "link_note/3 with cross-scope quest returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      quest = quest_fixture(scope1)
      note = note_fixture(scope2)

      # Quest exists in scope1, note is in scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Quests.link_note(scope1, quest.id, note.id)
    end

    test "link_note/3 with cross-scope note returns error" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      quest = quest_fixture(scope1)
      note = note_fixture(scope1)

      # Quest is in scope1, note is in scope1, but called with scope2, so quest_not_found is returned first
      assert {:error, :quest_not_found} = Quests.link_note(scope2, quest.id, note.id)
    end

    test "link_note/3 prevents duplicate links" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Quests.link_note(scope, quest.id, note.id)
      assert {:error, %Ecto.Changeset{}} = Quests.link_note(scope, quest.id, note.id)
    end

    test "unlink_note/3 successfully removes a quest-note link" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      {:ok, _link} = Quests.link_note(scope, quest.id, note.id)
      assert Quests.note_linked?(scope, quest.id, note.id)

      assert {:ok, _link} = Quests.unlink_note(scope, quest.id, note.id)
      refute Quests.note_linked?(scope, quest.id, note.id)
    end

    test "unlink_note/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      assert {:error, :not_found} = Quests.unlink_note(scope, quest.id, note.id)
    end

    test "unlink_note/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      note = note_fixture(scope)

      invalid_quest_id = Ecto.UUID.generate()
      assert {:error, :quest_not_found} = Quests.unlink_note(scope, invalid_quest_id, note.id)
    end

    test "unlink_note/3 with invalid note_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Quests.unlink_note(scope, quest.id, invalid_note_id)
    end

    test "note_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      refute Quests.note_linked?(scope, quest.id, note.id)
    end

    test "note_linked?/3 with invalid quest_id returns false" do
      scope = game_scope_fixture()
      note = note_fixture(scope)

      invalid_quest_id = Ecto.UUID.generate()
      refute Quests.note_linked?(scope, invalid_quest_id, note.id)
    end

    test "note_linked?/3 with invalid note_id returns false" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      refute Quests.note_linked?(scope, quest.id, invalid_note_id)
    end

    test "linked_notes/2 returns all notes linked to a quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)
      unlinked_note = note_fixture(scope)

      {:ok, _} = Quests.link_note(scope, quest.id, note1.id)
      {:ok, _} = Quests.link_note(scope, quest.id, note2.id)

      linked_notes_with_meta = Quests.linked_notes(scope, quest.id)
      assert length(linked_notes_with_meta) == 2
      linked_notes = Enum.map(linked_notes_with_meta, & &1.entity)
      assert note1 in linked_notes
      assert note2 in linked_notes
      refute unlinked_note in linked_notes
    end

    test "linked_notes/2 returns empty list for quest with no linked notes" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert Quests.linked_notes(scope, quest.id) == []
    end

    test "linked_notes/2 with invalid quest_id returns empty list" do
      scope = game_scope_fixture()

      invalid_quest_id = Ecto.UUID.generate()
      assert Quests.linked_notes(scope, invalid_quest_id) == []
    end

    test "linked_notes/2 respects scope boundaries" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()
      quest = quest_fixture(scope1)
      note = note_fixture(scope1)

      {:ok, _} = Quests.link_note(scope1, quest.id, note.id)

      # Same quest ID in different scope should return empty
      assert Quests.linked_notes(scope2, quest.id) == []
    end
  end

  describe "quest - character links" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.LocationsFixtures

    test "link_character/3 successfully links a quest and character" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Quests.link_character(scope, quest.id, character.id)
      assert Quests.character_linked?(scope, quest.id, character.id)
    end

    test "link_character/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      character = character_fixture(scope)

      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} =
               Quests.link_character(scope, invalid_quest_id, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Quests.link_character(scope, quest.id, invalid_character_id)
    end

    test "link_character/3 prevents duplicate links" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Quests.link_character(scope, quest.id, character.id)
      assert {:error, %Ecto.Changeset{}} = Quests.link_character(scope, quest.id, character.id)
    end

    test "unlink_character/3 successfully removes a quest-character link" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character = character_fixture(scope)

      {:ok, _link} = Quests.link_character(scope, quest.id, character.id)
      assert Quests.character_linked?(scope, quest.id, character.id)

      assert {:ok, _link} = Quests.unlink_character(scope, quest.id, character.id)
      refute Quests.character_linked?(scope, quest.id, character.id)
    end

    test "unlink_character/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character = character_fixture(scope)

      assert {:error, :not_found} = Quests.unlink_character(scope, quest.id, character.id)
    end

    test "character_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character = character_fixture(scope)

      refute Quests.character_linked?(scope, quest.id, character.id)
    end

    test "linked_characters/2 returns all characters linked to a quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)

      {:ok, _} = Quests.link_character(scope, quest.id, character1.id)
      {:ok, _} = Quests.link_character(scope, quest.id, character2.id)

      linked_characters_with_meta = Quests.linked_characters(scope, quest.id)
      assert length(linked_characters_with_meta) == 2
      linked_characters = Enum.map(linked_characters_with_meta, & &1.entity)
      assert character1 in linked_characters
      assert character2 in linked_characters
      refute unlinked_character in linked_characters
    end

    test "linked_characters/2 returns empty list for quest with no linked characters" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert Quests.linked_characters(scope, quest.id) == []
    end
  end

  describe "quest - faction links" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.LocationsFixtures

    test "link_faction/3 successfully links a quest and faction" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Quests.link_faction(scope, quest.id, faction.id)
      assert Quests.faction_linked?(scope, quest.id, faction.id)
    end

    test "link_faction/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)

      invalid_quest_id = Ecto.UUID.generate()
      assert {:error, :quest_not_found} = Quests.link_faction(scope, invalid_quest_id, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Quests.link_faction(scope, quest.id, invalid_faction_id)
    end

    test "link_faction/3 prevents duplicate links" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Quests.link_faction(scope, quest.id, faction.id)
      assert {:error, %Ecto.Changeset{}} = Quests.link_faction(scope, quest.id, faction.id)
    end

    test "unlink_faction/3 successfully removes a quest-faction link" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction = faction_fixture(scope)

      {:ok, _link} = Quests.link_faction(scope, quest.id, faction.id)
      assert Quests.faction_linked?(scope, quest.id, faction.id)

      assert {:ok, _link} = Quests.unlink_faction(scope, quest.id, faction.id)
      refute Quests.faction_linked?(scope, quest.id, faction.id)
    end

    test "unlink_faction/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction = faction_fixture(scope)

      assert {:error, :not_found} = Quests.unlink_faction(scope, quest.id, faction.id)
    end

    test "faction_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction = faction_fixture(scope)

      refute Quests.faction_linked?(scope, quest.id, faction.id)
    end

    test "linked_factions/2 returns all factions linked to a quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)
      unlinked_faction = faction_fixture(scope)

      {:ok, _} = Quests.link_faction(scope, quest.id, faction1.id)
      {:ok, _} = Quests.link_faction(scope, quest.id, faction2.id)

      linked_factions_with_meta = Quests.linked_factions(scope, quest.id)
      assert length(linked_factions_with_meta) == 2
      linked_factions = Enum.map(linked_factions_with_meta, & &1.entity)
      assert faction1 in linked_factions
      assert faction2 in linked_factions
      refute unlinked_faction in linked_factions
    end

    test "linked_factions/2 returns empty list for quest with no linked factions" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert Quests.linked_factions(scope, quest.id) == []
    end
  end

  describe "quest - location links" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.FactionsFixtures
    import GameMasterCore.LocationsFixtures

    test "link_location/3 successfully links a quest and location" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location = location_fixture(scope)

      assert {:ok, _link} = Quests.link_location(scope, quest.id, location.id)
      assert Quests.location_linked?(scope, quest.id, location.id)
    end

    test "link_location/3 with invalid quest_id returns error" do
      scope = game_scope_fixture()
      location = location_fixture(scope)

      invalid_quest_id = Ecto.UUID.generate()

      assert {:error, :quest_not_found} =
               Quests.link_location(scope, invalid_quest_id, location.id)
    end

    test "link_location/3 with invalid location_id returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Quests.link_location(scope, quest.id, invalid_location_id)
    end

    test "link_location/3 prevents duplicate links" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location = location_fixture(scope)

      assert {:ok, _link} = Quests.link_location(scope, quest.id, location.id)
      assert {:error, %Ecto.Changeset{}} = Quests.link_location(scope, quest.id, location.id)
    end

    test "unlink_location/3 successfully removes a quest-location link" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location = location_fixture(scope)

      {:ok, _link} = Quests.link_location(scope, quest.id, location.id)
      assert Quests.location_linked?(scope, quest.id, location.id)

      assert {:ok, _link} = Quests.unlink_location(scope, quest.id, location.id)
      refute Quests.location_linked?(scope, quest.id, location.id)
    end

    test "unlink_location/3 with non-existent link returns error" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location = location_fixture(scope)

      assert {:error, :not_found} = Quests.unlink_location(scope, quest.id, location.id)
    end

    test "location_linked?/3 returns false for unlinked entities" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location = location_fixture(scope)

      refute Quests.location_linked?(scope, quest.id, location.id)
    end

    test "linked_locations/2 returns all locations linked to a quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      location1 = location_fixture(scope)
      location2 = location_fixture(scope)
      unlinked_location = location_fixture(scope)

      {:ok, _} = Quests.link_location(scope, quest.id, location1.id)
      {:ok, _} = Quests.link_location(scope, quest.id, location2.id)

      linked_locations_with_meta = Quests.linked_locations(scope, quest.id)
      assert length(linked_locations_with_meta) == 2
      linked_locations = Enum.map(linked_locations_with_meta, & &1.entity)
      assert location1 in linked_locations
      assert location2 in linked_locations
      refute unlinked_location in linked_locations
    end

    test "linked_locations/2 returns empty list for quest with no linked locations" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert Quests.linked_locations(scope, quest.id) == []
    end
  end

  describe "quest tree" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures

    test "list_quests_tree_for_game/1 returns empty list when no quests exist" do
      scope = game_scope_fixture()

      assert Quests.list_quests_tree_for_game(scope) == []
    end

    test "list_quests_tree_for_game/1 returns flat tree for root quests" do
      scope = game_scope_fixture()

      quest1 =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Ancient Prophecy",
          content: "Discover prophecy",
          parent_id: nil
        })

      quest2 =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Dragon Hunt",
          content: "Hunt dragon",
          parent_id: nil
        })

      tree = Quests.list_quests_tree_for_game(scope)

      assert length(tree) == 2
      # Should be sorted by name
      [first, second] = tree
      assert first.id == quest1.id
      assert first.name == "Ancient Prophecy"
      assert first.children == []

      assert second.id == quest2.id
      assert second.name == "Dragon Hunt"
      assert second.children == []
    end

    test "list_quests_tree_for_game/1 builds hierarchical structure correctly" do
      scope = game_scope_fixture()

      # Create main quest (root)
      main_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "The Great Adventure",
          content: "Embark on adventure",
          parent_id: nil
        })

      # Create sub-quest (child of main quest)
      sub_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Find the Key",
          content: "Locate ancient key",
          parent_id: main_quest.id
        })

      # Create final quest (child of sub-quest)
      final_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Open the Door",
          content: "Use key to open door",
          parent_id: sub_quest.id
        })

      tree = Quests.list_quests_tree_for_game(scope)

      assert length(tree) == 1
      [main_node] = tree
      assert main_node.id == main_quest.id
      assert main_node.name == "The Great Adventure"
      assert main_node.parent_id == nil

      assert length(main_node.children) == 1
      [sub_node] = main_node.children
      assert sub_node.id == sub_quest.id
      assert sub_node.name == "Find the Key"
      assert sub_node.parent_id == main_quest.id

      assert length(sub_node.children) == 1
      [final_node] = sub_node.children
      assert final_node.id == final_quest.id
      assert final_node.name == "Open the Door"
      assert final_node.parent_id == sub_quest.id
      assert final_node.children == []
    end

    test "list_quests_tree_for_game/1 handles multiple children correctly" do
      scope = game_scope_fixture()

      # Create parent quest
      main_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Main Quest",
          content: "Main quest content",
          parent_id: nil
        })

      # Create multiple children
      quest1 =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Zebra Quest",
          content: "Zebra content",
          parent_id: main_quest.id
        })

      quest2 =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Alpha Quest",
          content: "Alpha content",
          parent_id: main_quest.id
        })

      tree = Quests.list_quests_tree_for_game(scope)

      [main_node] = tree
      assert length(main_node.children) == 2

      # Should be sorted by name
      [child1, child2] = main_node.children
      assert child1.name == "Alpha Quest"
      assert child1.id == quest2.id

      assert child2.name == "Zebra Quest"
      assert child2.id == quest1.id
    end

    test "list_quests_tree_for_game/1 includes all quest fields" do
      scope = game_scope_fixture()

      quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Test Quest",
          content: "Test quest content",
          content_plain_text: "Test quest content plain",
          tags: ["test", "example"],
          parent_id: nil
        })

      tree = Quests.list_quests_tree_for_game(scope)

      [node] = tree
      assert node.id == quest.id
      assert node.name == "Test Quest"
      assert node.content == "Test quest content"
      assert node.content_plain_text == "Test quest content plain"
      assert node.tags == ["test", "example"]
      assert node.parent_id == nil
      assert node.children == []
    end

    test "list_quests_tree_for_game/1 only returns quests for specified game" do
      scope1 = game_scope_fixture()
      scope2 = game_scope_fixture()

      # Create quest in game1
      _quest1 =
        quest_fixture(scope1, %{
          game_id: scope1.game.id,
          name: "Game 1 Quest",
          content: "Game 1 content"
        })

      # Create quest in game2  
      _quest2 =
        quest_fixture(scope2, %{
          game_id: scope2.game.id,
          name: "Game 2 Quest",
          content: "Game 2 content"
        })

      # Test game1
      tree1 = Quests.list_quests_tree_for_game(scope1)
      assert length(tree1) == 1
      [node1] = tree1
      assert node1.name == "Game 1 Quest"

      # Test game2
      tree2 = Quests.list_quests_tree_for_game(scope2)
      assert length(tree2) == 1
      [node2] = tree2
      assert node2.name == "Game 2 Quest"
    end

    test "list_quests_tree_for_game/1 handles deep nesting" do
      scope = game_scope_fixture()

      # Create 4-level hierarchy
      main_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Main Quest",
          content: "Main content",
          parent_id: nil
        })

      sub_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Sub Quest",
          content: "Sub content",
          parent_id: main_quest.id
        })

      sub_sub_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Sub Sub Quest",
          content: "Sub sub content",
          parent_id: sub_quest.id
        })

      _final_quest =
        quest_fixture(scope, %{
          game_id: scope.game.id,
          name: "Final Quest",
          content: "Final content",
          parent_id: sub_sub_quest.id
        })

      tree = Quests.list_quests_tree_for_game(scope)

      [main_node] = tree
      [sub_node] = main_node.children
      [sub_sub_node] = sub_node.children
      [final_node] = sub_sub_node.children

      assert main_node.name == "Main Quest"
      assert sub_node.name == "Sub Quest"
      assert sub_sub_node.name == "Sub Sub Quest"
      assert final_node.name == "Final Quest"
      assert final_node.children == []
    end
  end
end
