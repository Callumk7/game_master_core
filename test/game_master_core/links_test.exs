defmodule GameMasterCore.LinksTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Links
  alias GameMasterCore.Characters.CharacterNote

  import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures

  describe "link/2 and unlink/2 - Character and Note" do
    setup do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      note = note_fixture(scope)
      {:ok, scope: scope, character: character, note: note}
    end

    test "successfully links a character and note", %{character: character, note: note} do
      assert {:ok, %CharacterNote{}} = Links.link(character, note)
      assert Links.linked?(character, note)
    end

    test "successfully links a note and character (order doesn't matter)", %{
      character: character,
      note: note
    } do
      assert {:ok, %CharacterNote{}} = Links.link(note, character)
      assert Links.linked?(character, note)
    end

    test "prevents duplicate links", %{character: character, note: note} do
      assert {:ok, %CharacterNote{}} = Links.link(character, note)
      assert {:error, %Ecto.Changeset{}} = Links.link(character, note)
    end

    test "successfully unlinks a character and note", %{character: character, note: note} do
      {:ok, _link} = Links.link(character, note)
      assert Links.linked?(character, note)

      assert {:ok, %CharacterNote{}} = Links.unlink(character, note)
      refute Links.linked?(character, note)
    end

    test "successfully unlinks a note and character (order doesn't matter)", %{
      character: character,
      note: note
    } do
      {:ok, _link} = Links.link(character, note)
      assert Links.linked?(character, note)

      assert {:ok, %CharacterNote{}} = Links.unlink(note, character)
      refute Links.linked?(character, note)
    end

    test "returns error when unlinking non-existent link", %{character: character, note: note} do
      assert {:error, :not_found} = Links.unlink(character, note)
    end

    test "linked?/2 returns false for unlinked entities", %{character: character, note: note} do
      refute Links.linked?(character, note)
      refute Links.linked?(note, character)
    end
  end

  describe "links_for/1 - Character and Note" do
    setup do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)

      {:ok, _} = Links.link(character, note1)
      {:ok, _} = Links.link(character, note2)

      {:ok, scope: scope, character: character, note1: note1, note2: note2}
    end

    test "returns all linked notes for a character", %{
      character: character,
      note1: note1,
      note2: note2
    } do
      links = Links.links_for(character)
      assert %{notes: notes} = links
      assert length(notes) == 2
      assert note1 in notes
      assert note2 in notes
    end

    test "returns all linked characters for a note", %{character: character, note1: note1} do
      links = Links.links_for(note1)
      assert %{characters: characters} = links
      assert length(characters) == 1
      assert character in characters
    end

    test "returns empty list for entity with no links" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      links = Links.links_for(character)
      assert %{notes: []} = links
    end
  end

  describe "unimplemented entity combinations (TDD - should fail until implemented)" do
    setup do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      note = note_fixture(scope)

      # Mock structs for unimplemented entities
      faction = %{__struct__: GameMasterCore.Factions.Faction, id: 1}
      item = %{__struct__: GameMasterCore.Items.Item, id: 1}
      location = %{__struct__: GameMasterCore.Locations.Location, id: 1}
      quest = %{__struct__: GameMasterCore.Quests.Quest, id: 1}

      {:ok,
       character: character,
       note: note,
       faction: faction,
       item: item,
       location: location,
       quest: quest}
    end

    test "character-faction links should work", %{character: character, faction: faction} do
      assert {:ok, _link} = Links.link(character, faction)
      assert Links.linked?(character, faction)
      assert Links.linked?(faction, character)

      assert {:ok, _link} = Links.unlink(character, faction)
      refute Links.linked?(character, faction)
    end

    test "character-item links should work", %{character: character, item: item} do
      assert {:ok, _link} = Links.link(character, item)
      assert Links.linked?(character, item)
      assert Links.linked?(item, character)

      assert {:ok, _link} = Links.unlink(character, item)
      refute Links.linked?(character, item)
    end

    test "character-location links should work", %{character: character, location: location} do
      assert {:ok, _link} = Links.link(character, location)
      assert Links.linked?(character, location)
      assert Links.linked?(location, character)

      assert {:ok, _link} = Links.unlink(character, location)
      refute Links.linked?(character, location)
    end

    test "character-quest links should work", %{character: character, quest: quest} do
      assert {:ok, _link} = Links.link(character, quest)
      assert Links.linked?(character, quest)
      assert Links.linked?(quest, character)

      assert {:ok, _link} = Links.unlink(character, quest)
      refute Links.linked?(character, quest)
    end

    test "faction-note links should work", %{faction: faction, note: note} do
      assert {:ok, _link} = Links.link(faction, note)
      assert Links.linked?(faction, note)
      assert Links.linked?(note, faction)

      assert {:ok, _link} = Links.unlink(faction, note)
      refute Links.linked?(faction, note)
    end

    test "faction-item links should work", %{faction: faction, item: item} do
      assert {:ok, _link} = Links.link(faction, item)
      assert Links.linked?(faction, item)
      assert Links.linked?(item, faction)

      assert {:ok, _link} = Links.unlink(faction, item)
      refute Links.linked?(faction, item)
    end

    test "faction-location links should work", %{faction: faction, location: location} do
      assert {:ok, _link} = Links.link(faction, location)
      assert Links.linked?(faction, location)
      assert Links.linked?(location, faction)

      assert {:ok, _link} = Links.unlink(faction, location)
      refute Links.linked?(faction, location)
    end

    test "faction-quest links should work", %{faction: faction, quest: quest} do
      assert {:ok, _link} = Links.link(faction, quest)
      assert Links.linked?(faction, quest)
      assert Links.linked?(quest, faction)

      assert {:ok, _link} = Links.unlink(faction, quest)
      refute Links.linked?(faction, quest)
    end

    test "note-item links should work", %{note: note, item: item} do
      assert {:ok, _link} = Links.link(note, item)
      assert Links.linked?(note, item)
      assert Links.linked?(item, note)

      assert {:ok, _link} = Links.unlink(note, item)
      refute Links.linked?(note, item)
    end

    test "note-location links should work", %{note: note, location: location} do
      assert {:ok, _link} = Links.link(note, location)
      assert Links.linked?(note, location)
      assert Links.linked?(location, note)

      assert {:ok, _link} = Links.unlink(note, location)
      refute Links.linked?(note, location)
    end

    test "note-quest links should work", %{note: note, quest: quest} do
      assert {:ok, _link} = Links.link(note, quest)
      assert Links.linked?(note, quest)
      assert Links.linked?(quest, note)

      assert {:ok, _link} = Links.unlink(note, quest)
      refute Links.linked?(note, quest)
    end

    test "item-location links should work", %{item: item, location: location} do
      assert {:ok, _link} = Links.link(item, location)
      assert Links.linked?(item, location)
      assert Links.linked?(location, item)

      assert {:ok, _link} = Links.unlink(item, location)
      refute Links.linked?(item, location)
    end

    test "item-quest links should work", %{item: item, quest: quest} do
      assert {:ok, _link} = Links.link(item, quest)
      assert Links.linked?(item, quest)
      assert Links.linked?(quest, item)

      assert {:ok, _link} = Links.unlink(item, quest)
      refute Links.linked?(item, quest)
    end

    test "location-quest links should work", %{location: location, quest: quest} do
      assert {:ok, _link} = Links.link(location, quest)
      assert Links.linked?(location, quest)
      assert Links.linked?(quest, location)

      assert {:ok, _link} = Links.unlink(location, quest)
      refute Links.linked?(location, quest)
    end
  end

  describe "links_for/1 - unimplemented entities (TDD - should fail until implemented)" do
    test "should return linked entities for factions, items, locations, and quests" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      note = note_fixture(scope)

      faction = %{__struct__: GameMasterCore.Factions.Faction, id: 1}
      item = %{__struct__: GameMasterCore.Items.Item, id: 1}
      location = %{__struct__: GameMasterCore.Locations.Location, id: 1}
      quest = %{__struct__: GameMasterCore.Quests.Quest, id: 1}

      # Link some entities first
      {:ok, _} = Links.link(faction, character)
      {:ok, _} = Links.link(faction, note)
      {:ok, _} = Links.link(item, character)
      {:ok, _} = Links.link(location, note)
      {:ok, _} = Links.link(quest, character)

      # Should return linked entities
      faction_links = Links.links_for(faction)
      assert %{characters: [^character], notes: [^note]} = faction_links

      item_links = Links.links_for(item)
      assert %{characters: [^character]} = item_links

      location_links = Links.links_for(location)
      assert %{notes: [^note]} = location_links

      quest_links = Links.links_for(quest)
      assert %{characters: [^character]} = quest_links
    end
  end
end
