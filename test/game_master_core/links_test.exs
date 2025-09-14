defmodule GameMasterCore.LinksTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Links
  alias GameMasterCore.Characters.CharacterNote

  import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0, game_scope_fixture: 0]
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  import GameMasterCore.QuestsFixtures

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

  describe "link/2 and unlink/2 - Character and Faction" do
    setup do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      faction = faction_fixture(scope)
      {:ok, scope: scope, character: character, faction: faction}
    end

    test "successfully links a character and faction", %{character: character, faction: faction} do
      assert {:ok, _link} = Links.link(character, faction)
      assert Links.linked?(character, faction)
    end

    test "successfully links a faction and character (order doesn't matter)", %{
      character: character,
      faction: faction
    } do
      assert {:ok, _link} = Links.link(faction, character)
      assert Links.linked?(character, faction)
    end

    test "prevents duplicate links", %{character: character, faction: faction} do
      assert {:ok, _link} = Links.link(character, faction)
      assert {:error, %Ecto.Changeset{}} = Links.link(character, faction)
    end

    test "successfully unlinks a character and faction", %{character: character, faction: faction} do
      {:ok, _link} = Links.link(character, faction)
      assert Links.linked?(character, faction)

      assert {:ok, _link} = Links.unlink(character, faction)
      refute Links.linked?(character, faction)
    end
  end

  describe "link/2 and unlink/2 - Character and Location" do
    setup do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      location = location_fixture(scope)
      {:ok, scope: scope, character: character, location: location}
    end

    test "successfully links a character and location", %{
      character: character,
      location: location
    } do
      assert {:ok, _link} = Links.link(character, location)
      assert Links.linked?(character, location)
    end

    test "successfully unlinks a character and location", %{
      character: character,
      location: location
    } do
      {:ok, _link} = Links.link(character, location)
      assert {:ok, _link} = Links.unlink(character, location)
      refute Links.linked?(character, location)
    end
  end

  describe "link/2 and unlink/2 - Character and Quest" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope)
      quest = quest_fixture(scope)
      {:ok, scope: scope, character: character, quest: quest}
    end

    test "successfully links a character and quest", %{character: character, quest: quest} do
      assert {:ok, _link} = Links.link(character, quest)
      assert Links.linked?(character, quest)
    end

    test "successfully unlinks a character and quest", %{character: character, quest: quest} do
      {:ok, _link} = Links.link(character, quest)
      assert {:ok, _link} = Links.unlink(character, quest)
      refute Links.linked?(character, quest)
    end
  end

  describe "link/2 and unlink/2 - Note and Faction" do
    setup do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      faction = faction_fixture(scope)
      {:ok, scope: scope, note: note, faction: faction}
    end

    test "successfully links a note and faction", %{note: note, faction: faction} do
      assert {:ok, _link} = Links.link(note, faction)
      assert Links.linked?(note, faction)
    end

    test "successfully unlinks a note and faction", %{note: note, faction: faction} do
      {:ok, _link} = Links.link(note, faction)
      assert {:ok, _link} = Links.unlink(note, faction)
      refute Links.linked?(note, faction)
    end
  end

  describe "link/2 and unlink/2 - Note and Location" do
    setup do
      scope = user_scope_fixture()
      note = note_fixture(scope)
      location = location_fixture(scope)
      {:ok, scope: scope, note: note, location: location}
    end

    test "successfully links a note and location", %{note: note, location: location} do
      assert {:ok, _link} = Links.link(note, location)
      assert Links.linked?(note, location)
    end

    test "successfully unlinks a note and location", %{note: note, location: location} do
      {:ok, _link} = Links.link(note, location)
      assert {:ok, _link} = Links.unlink(note, location)
      refute Links.linked?(note, location)
    end
  end

  describe "link/2 and unlink/2 - Note and Quest" do
    setup do
      scope = game_scope_fixture()
      note = note_fixture(scope)
      quest = quest_fixture(scope)
      {:ok, scope: scope, note: note, quest: quest}
    end

    test "successfully links a note and quest", %{note: note, quest: quest} do
      assert {:ok, _link} = Links.link(note, quest)
      assert Links.linked?(note, quest)
    end

    test "successfully unlinks a note and quest", %{note: note, quest: quest} do
      {:ok, _link} = Links.link(note, quest)
      assert {:ok, _link} = Links.unlink(note, quest)
      refute Links.linked?(note, quest)
    end
  end

  describe "link/2 and unlink/2 - Faction and Location" do
    setup do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)
      location = location_fixture(scope)
      {:ok, scope: scope, faction: faction, location: location}
    end

    test "successfully links a faction and location", %{faction: faction, location: location} do
      assert {:ok, _link} = Links.link(faction, location)
      assert Links.linked?(faction, location)
    end

    test "successfully unlinks a faction and location", %{faction: faction, location: location} do
      {:ok, _link} = Links.link(faction, location)
      assert {:ok, _link} = Links.unlink(faction, location)
      refute Links.linked?(faction, location)
    end
  end

  describe "link/2 and unlink/2 - Faction and Quest" do
    setup do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      quest = quest_fixture(scope)
      {:ok, scope: scope, faction: faction, quest: quest}
    end

    test "successfully links a faction and quest", %{faction: faction, quest: quest} do
      assert {:ok, _link} = Links.link(faction, quest)
      assert Links.linked?(faction, quest)
    end

    test "successfully unlinks a faction and quest", %{faction: faction, quest: quest} do
      {:ok, _link} = Links.link(faction, quest)
      assert {:ok, _link} = Links.unlink(faction, quest)
      refute Links.linked?(faction, quest)
    end
  end

  describe "link/2 and unlink/2 - Location and Quest" do
    setup do
      scope = game_scope_fixture()
      location = location_fixture(scope)
      quest = quest_fixture(scope)
      {:ok, scope: scope, location: location, quest: quest}
    end

    test "successfully links a location and quest", %{location: location, quest: quest} do
      assert {:ok, _link} = Links.link(location, quest)
      assert Links.linked?(location, quest)
    end

    test "successfully unlinks a location and quest", %{location: location, quest: quest} do
      {:ok, _link} = Links.link(location, quest)
      assert {:ok, _link} = Links.unlink(location, quest)
      refute Links.linked?(location, quest)
    end
  end

  describe "link/2 and unlink/2 - Character self-join" do
    setup do
      scope = user_scope_fixture()
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      {:ok, scope: scope, character1: character1, character2: character2}
    end

    test "successfully links two characters", %{character1: character1, character2: character2} do
      assert {:ok, _link} = Links.link(character1, character2)
      assert Links.linked?(character1, character2)
    end

    test "successfully links two characters (order doesn't matter)", %{
      character1: character1,
      character2: character2
    } do
      assert {:ok, _link} = Links.link(character2, character1)
      assert Links.linked?(character1, character2)
    end

    test "prevents duplicate character links", %{character1: character1, character2: character2} do
      assert {:ok, _link} = Links.link(character1, character2)
      assert {:error, %Ecto.Changeset{}} = Links.link(character1, character2)
    end

    test "successfully unlinks two characters", %{character1: character1, character2: character2} do
      {:ok, _link} = Links.link(character1, character2)
      assert Links.linked?(character1, character2)

      assert {:ok, _link} = Links.unlink(character1, character2)
      refute Links.linked?(character1, character2)
    end

    test "returns error when unlinking non-existent character link", %{
      character1: character1,
      character2: character2
    } do
      assert {:error, :not_found} = Links.unlink(character1, character2)
    end

    test "character cannot link to itself", %{character1: character1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(character1, character1)
    end
  end

  describe "link/2 and unlink/2 - Note self-join" do
    setup do
      scope = user_scope_fixture()
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)
      {:ok, scope: scope, note1: note1, note2: note2}
    end

    test "successfully links two notes", %{note1: note1, note2: note2} do
      assert {:ok, _link} = Links.link(note1, note2)
      assert Links.linked?(note1, note2)
    end

    test "successfully unlinks two notes", %{note1: note1, note2: note2} do
      {:ok, _link} = Links.link(note1, note2)
      assert {:ok, _link} = Links.unlink(note1, note2)
      refute Links.linked?(note1, note2)
    end

    test "note cannot link to itself", %{note1: note1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(note1, note1)
    end
  end

  describe "link/2 and unlink/2 - Faction self-join" do
    setup do
      scope = user_scope_fixture()
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)
      {:ok, scope: scope, faction1: faction1, faction2: faction2}
    end

    test "successfully links two factions", %{faction1: faction1, faction2: faction2} do
      assert {:ok, _link} = Links.link(faction1, faction2)
      assert Links.linked?(faction1, faction2)
    end

    test "successfully unlinks two factions", %{faction1: faction1, faction2: faction2} do
      {:ok, _link} = Links.link(faction1, faction2)
      assert {:ok, _link} = Links.unlink(faction1, faction2)
      refute Links.linked?(faction1, faction2)
    end

    test "faction cannot link to itself", %{faction1: faction1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(faction1, faction1)
    end
  end

  describe "link/2 and unlink/2 - Location self-join" do
    setup do
      scope = user_scope_fixture()
      location1 = location_fixture(scope)
      location2 = location_fixture(scope)
      {:ok, scope: scope, location1: location1, location2: location2}
    end

    test "successfully links two locations", %{location1: location1, location2: location2} do
      assert {:ok, _link} = Links.link(location1, location2)
      assert Links.linked?(location1, location2)
    end

    test "successfully unlinks two locations", %{location1: location1, location2: location2} do
      {:ok, _link} = Links.link(location1, location2)
      assert {:ok, _link} = Links.unlink(location1, location2)
      refute Links.linked?(location1, location2)
    end

    test "location cannot link to itself", %{location1: location1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(location1, location1)
    end
  end

  describe "link/2 and unlink/2 - Quest self-join" do
    setup do
      scope = game_scope_fixture()
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)
      {:ok, scope: scope, quest1: quest1, quest2: quest2}
    end

    test "successfully links two quests", %{quest1: quest1, quest2: quest2} do
      assert {:ok, _link} = Links.link(quest1, quest2)
      assert Links.linked?(quest1, quest2)
    end

    test "successfully unlinks two quests", %{quest1: quest1, quest2: quest2} do
      {:ok, _link} = Links.link(quest1, quest2)
      assert {:ok, _link} = Links.unlink(quest1, quest2)
      refute Links.linked?(quest1, quest2)
    end

    test "quest cannot link to itself", %{quest1: quest1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(quest1, quest1)
    end
  end

  describe "links_for/1 - all entity types" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope)
      note = note_fixture(scope)
      faction = faction_fixture(scope)
      location = location_fixture(scope)
      quest = quest_fixture(scope)

      {:ok,
       scope: scope,
       character: character,
       note: note,
       faction: faction,
       location: location,
       quest: quest}
    end

    test "returns all linked entities for a character", %{
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    } do
      {:ok, _} = Links.link(character, note)
      {:ok, _} = Links.link(character, faction)
      {:ok, _} = Links.link(character, location)
      {:ok, _} = Links.link(character, quest)

      links = Links.links_for(character)
      assert %{notes: notes, factions: factions, locations: locations, quests: quests} = links
      assert note in notes
      assert faction in factions
      assert location in locations
      assert quest in quests
    end

    test "returns all linked entities for a faction", %{
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    } do
      {:ok, _} = Links.link(faction, character)
      {:ok, _} = Links.link(faction, note)
      {:ok, _} = Links.link(faction, location)
      {:ok, _} = Links.link(faction, quest)

      links = Links.links_for(faction)
      assert %{characters: characters, notes: notes, locations: locations, quests: quests} = links
      assert character in characters
      assert note in notes
      assert location in locations
      assert quest in quests
    end

    test "returns all linked entities for a location", %{
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    } do
      {:ok, _} = Links.link(location, character)
      {:ok, _} = Links.link(location, note)
      {:ok, _} = Links.link(location, faction)
      {:ok, _} = Links.link(location, quest)

      links = Links.links_for(location)
      assert %{characters: characters, notes: notes, factions: factions, quests: quests} = links
      assert character in characters
      assert note in notes
      assert faction in factions
      assert quest in quests
    end

    test "returns all linked entities for a quest", %{
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    } do
      {:ok, _} = Links.link(quest, character)
      {:ok, _} = Links.link(quest, note)
      {:ok, _} = Links.link(quest, faction)
      {:ok, _} = Links.link(quest, location)

      links = Links.links_for(quest)

      assert %{characters: characters, notes: notes, factions: factions, locations: locations} =
               links

      assert character in characters
      assert note in notes
      assert faction in factions
      assert location in locations
    end

    test "returns empty lists for entity with no links" do
      scope = game_scope_fixture()
      character = character_fixture(scope)

      links = Links.links_for(character)
      assert %{notes: [], factions: [], locations: [], quests: []} = links
    end
  end

  describe "links_for/1 - self-join properties" do
    test "returns self-linked characters for a character" do
      scope = user_scope_fixture()
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      character3 = character_fixture(scope)

      {:ok, _} = Links.link(character1, character2)
      {:ok, _} = Links.link(character1, character3)

      links = Links.links_for(character1)
      assert %{characters: characters} = links
      assert length(characters) == 2
      assert character2 in characters
      assert character3 in characters
    end

    test "returns self-linked notes for a note" do
      scope = user_scope_fixture()
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)

      {:ok, _} = Links.link(note1, note2)

      links = Links.links_for(note1)
      assert %{notes: notes} = links
      assert length(notes) == 1
      assert note2 in notes
    end

    test "returns self-linked factions for a faction" do
      scope = user_scope_fixture()
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)

      {:ok, _} = Links.link(faction1, faction2)

      links = Links.links_for(faction1)
      assert %{factions: factions} = links
      assert length(factions) == 1
      assert faction2 in factions
    end

    test "returns self-linked locations for a location" do
      scope = user_scope_fixture()
      location1 = location_fixture(scope)
      location2 = location_fixture(scope)

      {:ok, _} = Links.link(location1, location2)

      links = Links.links_for(location1)
      assert %{locations: locations} = links
      assert length(locations) == 1
      assert location2 in locations
    end

    test "returns self-linked quests for a quest" do
      scope = game_scope_fixture()
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)

      {:ok, _} = Links.link(quest1, quest2)

      links = Links.links_for(quest1)
      assert %{quests: quests} = links
      assert length(quests) == 1
      assert quest2 in quests
    end
  end
end
