defmodule GameMasterCore.LinksTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Links
  alias GameMasterCore.Characters.CharacterNote

  import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  import GameMasterCore.QuestsFixtures
  import GameMasterCore.GamesFixtures

  describe "link/2 and unlink/2 - Character and Note" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note1 = note_fixture(scope, %{game_id: scope.game.id})
      note2 = note_fixture(scope, %{game_id: scope.game.id})

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
      linked_notes = Enum.map(notes, & &1.entity)
      assert note1 in linked_notes
      assert note2 in linked_notes
    end

    test "returns all linked characters for a note", %{character: character, note1: note1} do
      links = Links.links_for(note1)
      assert %{characters: characters} = links
      assert length(characters) == 1
      linked_characters = Enum.map(characters, & &1.entity)
      assert character in linked_characters
    end

    test "returns empty list for entity with no links" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      links = Links.links_for(character)
      assert %{notes: []} = links
    end
  end

  describe "link/2 and unlink/2 - Character and Faction" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
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
      character = character_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      note = note_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
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
      note = note_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
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
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})
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
      location = location_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      character1 = character_fixture(scope, %{game_id: scope.game.id})
      character2 = character_fixture(scope, %{game_id: scope.game.id})
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

    test "prevents bidirectional duplicate character links", %{
      character1: character1,
      character2: character2
    } do
      # Create char1 -> char2
      assert {:ok, _link} = Links.link(character1, character2)

      # Attempt to create char2 -> char1 (should fail due to bidirectional constraint)
      assert {:error, %Ecto.Changeset{}} = Links.link(character2, character1)

      # Both directions should still show as linked
      assert Links.linked?(character1, character2)
      assert Links.linked?(character2, character1)
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
      scope = game_scope_fixture()
      note1 = note_fixture(scope, %{game_id: scope.game.id})
      note2 = note_fixture(scope, %{game_id: scope.game.id})
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

    test "prevents bidirectional duplicate note links", %{note1: note1, note2: note2} do
      # Create note1 -> note2
      assert {:ok, _link} = Links.link(note1, note2)

      # Attempt to create note2 -> note1 (should fail due to bidirectional constraint)
      assert {:error, %Ecto.Changeset{}} = Links.link(note2, note1)

      # Both directions should still show as linked
      assert Links.linked?(note1, note2)
      assert Links.linked?(note2, note1)
    end

    test "note cannot link to itself", %{note1: note1} do
      assert {:error, %Ecto.Changeset{}} = Links.link(note1, note1)
    end
  end

  describe "link/2 and unlink/2 - Faction self-join" do
    setup do
      scope = game_scope_fixture()
      faction1 = faction_fixture(scope, %{game_id: scope.game.id})
      faction2 = faction_fixture(scope, %{game_id: scope.game.id})
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
      scope = game_scope_fixture()
      location1 = location_fixture(scope, %{game_id: scope.game.id})
      location2 = location_fixture(scope, %{game_id: scope.game.id})
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
      quest1 = quest_fixture(scope, %{game_id: scope.game.id})
      quest2 = quest_fixture(scope, %{game_id: scope.game.id})
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
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

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
      assert note in Enum.map(notes, & &1.entity)
      assert faction in Enum.map(factions, & &1.entity)
      assert location in Enum.map(locations, & &1.entity)
      assert quest in Enum.map(quests, & &1.entity)
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
      assert character in Enum.map(characters, & &1.entity)
      assert note in Enum.map(notes, & &1.entity)
      assert location in Enum.map(locations, & &1.entity)
      assert quest in Enum.map(quests, & &1.entity)
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
      assert character in Enum.map(characters, & &1.entity)
      assert note in Enum.map(notes, & &1.entity)
      assert faction in Enum.map(factions, & &1.entity)
      assert quest in Enum.map(quests, & &1.entity)
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

      assert character in Enum.map(characters, & &1.entity)
      assert note in Enum.map(notes, & &1.entity)
      assert faction in Enum.map(factions, & &1.entity)
      assert location in Enum.map(locations, & &1.entity)
    end

    test "returns empty lists for entity with no links" do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})

      links = Links.links_for(character)
      assert %{notes: [], factions: [], locations: [], quests: []} = links
    end
  end

  describe "links_for/1 - self-join properties" do
    test "returns self-linked characters for a character" do
      scope = game_scope_fixture()
      character1 = character_fixture(scope, %{game_id: scope.game.id})
      character2 = character_fixture(scope, %{game_id: scope.game.id})
      character3 = character_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Links.link(character1, character2)
      {:ok, _} = Links.link(character1, character3)

      links = Links.links_for(character1)
      assert %{characters: characters} = links
      assert length(characters) == 2
      linked_characters = Enum.map(characters, & &1.entity)
      assert character2 in linked_characters
      assert character3 in linked_characters
    end

    test "returns self-linked notes for a note" do
      scope = game_scope_fixture()
      note1 = note_fixture(scope, %{game_id: scope.game.id})
      note2 = note_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Links.link(note1, note2)

      links = Links.links_for(note1)
      assert %{notes: notes} = links
      assert length(notes) == 1
      linked_notes = Enum.map(notes, & &1.entity)
      assert note2 in linked_notes
    end

    test "returns self-linked factions for a faction" do
      scope = game_scope_fixture()
      faction1 = faction_fixture(scope, %{game_id: scope.game.id})
      faction2 = faction_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Links.link(faction1, faction2)

      links = Links.links_for(faction1)
      assert %{factions: factions} = links
      assert length(factions) == 1
      linked_factions = Enum.map(factions, & &1.entity)
      assert faction2 in linked_factions
    end

    test "returns self-linked locations for a location" do
      scope = game_scope_fixture()
      location1 = location_fixture(scope, %{game_id: scope.game.id})
      location2 = location_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Links.link(location1, location2)

      links = Links.links_for(location1)
      assert %{locations: locations} = links
      assert length(locations) == 1
      linked_locations = Enum.map(locations, & &1.entity)
      assert location2 in linked_locations
    end

    test "returns self-linked quests for a quest" do
      scope = game_scope_fixture()
      quest1 = quest_fixture(scope, %{game_id: scope.game.id})
      quest2 = quest_fixture(scope, %{game_id: scope.game.id})

      {:ok, _} = Links.link(quest1, quest2)

      links = Links.links_for(quest1)
      assert %{quests: quests} = links
      assert length(quests) == 1
      linked_quests = Enum.map(quests, & &1.entity)
      assert quest2 in linked_quests
    end
  end

  describe "link/3 with metadata - Character and Note" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})
      {:ok, scope: scope, character: character, note: note}
    end

    test "successfully creates link with relationship_type metadata", %{
      character: character,
      note: note
    } do
      metadata = %{relationship_type: "ally"}

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.relationship_type == "ally"
    end

    test "successfully creates link with description metadata", %{
      character: character,
      note: note
    } do
      metadata = %{description: "Long-time allies from the war"}

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.description == "Long-time allies from the war"
    end

    test "successfully creates link with strength metadata", %{character: character, note: note} do
      metadata = %{strength: 8}

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.strength == 8
    end

    test "validates strength is between 1 and 10", %{character: character, note: note} do
      invalid_metadata_low = %{strength: 0}
      invalid_metadata_high = %{strength: 11}

      assert {:error, changeset} = Links.link(character, note, invalid_metadata_low)
      assert %{strength: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} = Links.link(character, note, invalid_metadata_high)
      assert %{strength: ["is invalid"]} = errors_on(changeset)
    end

    test "successfully creates link with is_active metadata", %{character: character, note: note} do
      metadata = %{is_active: false}

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.is_active == false
    end

    test "defaults is_active to true when not provided", %{character: character, note: note} do
      assert {:ok, link} = Links.link(character, note, %{})
      assert link.is_active == true
    end

    test "successfully creates link with JSON metadata", %{character: character, note: note} do
      json_metadata = %{
        "since" => "2021-01-01",
        "notes" => "Met during the siege",
        "importance" => "high"
      }

      metadata = %{metadata: json_metadata}

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.metadata == json_metadata
    end

    test "successfully creates link with all metadata fields", %{character: character, note: note} do
      metadata = %{
        relationship_type: "enemy",
        description: "Ancient rivalry dating back generations",
        strength: 9,
        is_active: true,
        metadata: %{
          "origin" => "family feud",
          "intensity" => "high",
          "public" => false
        }
      }

      assert {:ok, link} = Links.link(character, note, metadata)
      assert link.relationship_type == "enemy"
      assert link.description == "Ancient rivalry dating back generations"
      assert link.strength == 9
      assert link.is_active == true
      assert link.metadata["origin"] == "family feud"
      assert link.metadata["intensity"] == "high"
      assert link.metadata["public"] == false
    end
  end

  describe "link/3 with is_current_location metadata - Character and Location" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
      {:ok, scope: scope, character: character, location: location}
    end

    test "successfully creates character-location link with is_current_location true", %{
      character: character,
      location: location
    } do
      metadata = %{is_current_location: true}

      assert {:ok, link} = Links.link(character, location, metadata)
      assert link.is_current_location == true
    end

    test "successfully creates character-location link with is_current_location false", %{
      character: character,
      location: location
    } do
      metadata = %{is_current_location: false}

      assert {:ok, link} = Links.link(character, location, metadata)
      assert link.is_current_location == false
    end

    test "defaults is_current_location to false when not provided", %{
      character: character,
      location: location
    } do
      assert {:ok, link} = Links.link(character, location, %{})
      assert link.is_current_location == false
    end

    test "successfully creates character-location link with all metadata including is_current_location",
         %{
           character: character,
           location: location
         } do
      metadata = %{
        relationship_type: "resident",
        description: "Lives in the uptown district",
        strength: 8,
        is_active: true,
        is_current_location: true,
        metadata: %{
          "address" => "123 Main Street",
          "years_lived" => 5
        }
      }

      assert {:ok, link} = Links.link(character, location, metadata)
      assert link.relationship_type == "resident"
      assert link.description == "Lives in the uptown district"
      assert link.strength == 8
      assert link.is_active == true
      assert link.is_current_location == true
      assert link.metadata["address"] == "123 Main Street"
      assert link.metadata["years_lived"] == 5
    end
  end

  describe "link/3 with is_current_location metadata - Faction and Location" do
    setup do
      scope = game_scope_fixture()
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
      {:ok, scope: scope, faction: faction, location: location}
    end

    test "successfully creates faction-location link with is_current_location true", %{
      faction: faction,
      location: location
    } do
      metadata = %{is_current_location: true}

      assert {:ok, link} = Links.link(faction, location, metadata)
      assert link.is_current_location == true
    end

    test "successfully creates faction-location link with is_current_location false", %{
      faction: faction,
      location: location
    } do
      metadata = %{is_current_location: false}

      assert {:ok, link} = Links.link(faction, location, metadata)
      assert link.is_current_location == false
    end

    test "defaults is_current_location to false when not provided", %{
      faction: faction,
      location: location
    } do
      assert {:ok, link} = Links.link(faction, location, %{})
      assert link.is_current_location == false
    end

    test "successfully creates faction-location link with all metadata including is_current_location",
         %{
           faction: faction,
           location: location
         } do
      metadata = %{
        relationship_type: "headquartered",
        description: "Main operations center",
        strength: 10,
        is_active: true,
        is_current_location: true,
        metadata: %{
          "building_type" => "fortress",
          "established" => "2020-01-01"
        }
      }

      assert {:ok, link} = Links.link(faction, location, metadata)
      assert link.relationship_type == "headquartered"
      assert link.description == "Main operations center"
      assert link.strength == 10
      assert link.is_active == true
      assert link.is_current_location == true
      assert link.metadata["building_type"] == "fortress"
      assert link.metadata["established"] == "2020-01-01"
    end
  end

  describe "links_for/1 metadata retrieval" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note1 = note_fixture(scope, %{game_id: scope.game.id})
      note2 = note_fixture(scope, %{game_id: scope.game.id})

      # Create links with different metadata
      {:ok, _} =
        Links.link(character, note1, %{
          relationship_type: "ally",
          description: "Trusted companion",
          strength: 8,
          is_active: true,
          metadata: %{"bond_type" => "brotherhood"}
        })

      {:ok, _} =
        Links.link(character, note2, %{
          relationship_type: "mentor",
          description: "Former teacher",
          strength: 6,
          is_active: false,
          metadata: %{"subject" => "swordsmanship"}
        })

      {:ok, scope: scope, character: character, note1: note1, note2: note2}
    end

    test "returns metadata for all linked entities", %{
      character: character,
      note1: note1,
      note2: note2
    } do
      links = Links.links_for(character)
      assert %{notes: notes} = links
      assert length(notes) == 2

      # Find the specific notes in the results
      note1_link = Enum.find(notes, fn link -> link.entity.id == note1.id end)
      note2_link = Enum.find(notes, fn link -> link.entity.id == note2.id end)

      # Verify note1 metadata
      assert note1_link.relationship_type == "ally"
      assert note1_link.description == "Trusted companion"
      assert note1_link.strength == 8
      assert note1_link.is_active == true
      assert note1_link.metadata["bond_type"] == "brotherhood"

      # Verify note2 metadata
      assert note2_link.relationship_type == "mentor"
      assert note2_link.description == "Former teacher"
      assert note2_link.strength == 6
      assert note2_link.is_active == false
      assert note2_link.metadata["subject"] == "swordsmanship"
    end

    test "returns metadata from the reverse direction", %{
      character: character,
      note1: note1
    } do
      links = Links.links_for(note1)
      assert %{characters: characters} = links
      assert length(characters) == 1

      character_link = List.first(characters)
      assert character_link.entity.id == character.id
      assert character_link.relationship_type == "ally"
      assert character_link.description == "Trusted companion"
      assert character_link.strength == 8
      assert character_link.is_active == true
      assert character_link.metadata["bond_type"] == "brotherhood"
    end
  end

  describe "metadata across different entity types" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      {:ok,
       scope: scope, character: character, faction: faction, location: location, quest: quest}
    end

    test "character-faction link preserves metadata", %{character: character, faction: faction} do
      metadata = %{
        relationship_type: "member",
        description: "Loyal member since childhood",
        strength: 10,
        is_active: true,
        metadata: %{"rank" => "lieutenant", "years_served" => 15}
      }

      assert {:ok, link} = Links.link(character, faction, metadata)
      assert link.relationship_type == "member"
      assert link.strength == 10
      assert link.metadata["rank"] == "lieutenant"

      # Verify retrieval
      links = Links.links_for(character)
      faction_link = List.first(links.factions)
      assert faction_link.relationship_type == "member"
      assert faction_link.metadata["years_served"] == 15
    end

    test "character-location link preserves metadata", %{character: character, location: location} do
      metadata = %{
        relationship_type: "resident",
        description: "Lives in the merchant quarter",
        strength: 7,
        metadata: %{"address" => "123 Market Street", "owns_property" => true}
      }

      assert {:ok, link} = Links.link(character, location, metadata)
      assert link.relationship_type == "resident"

      links = Links.links_for(location)
      character_link = List.first(links.characters)
      assert character_link.metadata["address"] == "123 Market Street"
      assert character_link.metadata["owns_property"] == true
    end

    test "quest-character link preserves metadata", %{character: character, quest: quest} do
      metadata = %{
        relationship_type: "protagonist",
        description: "Main hero of the quest",
        strength: 9,
        metadata: %{"role" => "leader", "reward_share" => 50}
      }

      assert {:ok, _link} = Links.link(quest, character, metadata)

      links = Links.links_for(quest)
      character_link = List.first(links.characters)
      assert character_link.relationship_type == "protagonist"
      assert character_link.metadata["role"] == "leader"
    end
  end

  describe "self-join links with metadata" do
    setup do
      scope = game_scope_fixture()
      character1 = character_fixture(scope, %{game_id: scope.game.id})
      character2 = character_fixture(scope, %{game_id: scope.game.id})
      {:ok, scope: scope, character1: character1, character2: character2}
    end

    test "character-character link preserves metadata", %{
      character1: character1,
      character2: character2
    } do
      metadata = %{
        relationship_type: "sibling",
        description: "Twin brothers separated at birth",
        strength: 10,
        is_active: true,
        metadata: %{
          "birth_order" => "elder",
          "reunion_date" => "2023-05-15",
          "secret" => true
        }
      }

      assert {:ok, link} = Links.link(character1, character2, metadata)
      assert link.relationship_type == "sibling"
      assert link.metadata["birth_order"] == "elder"

      # Test bidirectional retrieval
      links1 = Links.links_for(character1)
      character2_link = List.first(links1.characters)
      assert character2_link.entity.id == character2.id
      assert character2_link.relationship_type == "sibling"
      assert character2_link.metadata["secret"] == true

      links2 = Links.links_for(character2)
      character1_link = List.first(links2.characters)
      assert character1_link.entity.id == character1.id
      assert character1_link.relationship_type == "sibling"
      assert character1_link.metadata["reunion_date"] == "2023-05-15"
    end
  end

  describe "links_for/1 metadata retrieval with is_current_location" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location1 = location_fixture(scope, %{game_id: scope.game.id})
      location2 = location_fixture(scope, %{game_id: scope.game.id})

      # Create links with is_current_location metadata
      {:ok, _} =
        Links.link(character, location1, %{
          relationship_type: "resident",
          description: "Current home",
          strength: 9,
          is_active: true,
          is_current_location: true,
          metadata: %{"address" => "123 Main St"}
        })

      {:ok, _} =
        Links.link(character, location2, %{
          relationship_type: "former_resident",
          description: "Childhood home",
          strength: 7,
          is_active: false,
          is_current_location: false,
          metadata: %{"years_lived" => 15}
        })

      {:ok, _} =
        Links.link(faction, location1, %{
          relationship_type: "headquartered",
          description: "Main operations center",
          strength: 10,
          is_active: true,
          is_current_location: true,
          metadata: %{"building_type" => "fortress"}
        })

      {:ok,
       scope: scope,
       character: character,
       faction: faction,
       location1: location1,
       location2: location2}
    end

    test "returns is_current_location metadata for character location links", %{
      character: character,
      location1: location1,
      location2: location2
    } do
      links = Links.links_for(character)
      assert %{locations: locations} = links
      assert length(locations) == 2

      # Find the specific locations in the results
      location1_link = Enum.find(locations, fn link -> link.entity.id == location1.id end)
      location2_link = Enum.find(locations, fn link -> link.entity.id == location2.id end)

      # Verify location1 metadata (current location)
      assert location1_link.relationship_type == "resident"
      assert location1_link.description == "Current home"
      assert location1_link.strength == 9
      assert location1_link.is_active == true
      assert location1_link.is_current_location == true
      assert location1_link.metadata["address"] == "123 Main St"

      # Verify location2 metadata (former location)
      assert location2_link.relationship_type == "former_resident"
      assert location2_link.description == "Childhood home"
      assert location2_link.strength == 7
      assert location2_link.is_active == false
      assert location2_link.is_current_location == false
      assert location2_link.metadata["years_lived"] == 15
    end

    test "returns is_current_location metadata for faction location links", %{
      faction: faction,
      location1: location1
    } do
      links = Links.links_for(faction)
      assert %{locations: locations} = links
      assert length(locations) == 1

      location_link = List.first(locations)
      assert location_link.entity.id == location1.id
      assert location_link.relationship_type == "headquartered"
      assert location_link.description == "Main operations center"
      assert location_link.strength == 10
      assert location_link.is_active == true
      assert location_link.is_current_location == true
      assert location_link.metadata["building_type"] == "fortress"
    end

    test "returns is_current_location metadata from reverse direction (location -> character)", %{
      character: character,
      location1: location1
    } do
      links = Links.links_for(location1)
      assert %{characters: characters} = links
      assert length(characters) == 1

      character_link = List.first(characters)
      assert character_link.entity.id == character.id
      assert character_link.relationship_type == "resident"
      assert character_link.description == "Current home"
      assert character_link.strength == 9
      assert character_link.is_active == true
      assert character_link.is_current_location == true
      assert character_link.metadata["address"] == "123 Main St"
    end

    test "returns is_current_location metadata from reverse direction (location -> faction)", %{
      faction: faction,
      location1: location1
    } do
      links = Links.links_for(location1)
      assert %{factions: factions} = links
      assert length(factions) == 1

      faction_link = List.first(factions)
      assert faction_link.entity.id == faction.id
      assert faction_link.relationship_type == "headquartered"
      assert faction_link.description == "Main operations center"
      assert faction_link.strength == 10
      assert faction_link.is_active == true
      assert faction_link.is_current_location == true
      assert faction_link.metadata["building_type"] == "fortress"
    end
  end

  describe "complex tree operations accuracy" do
    setup do
      scope = game_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      # Create a complex location hierarchy
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Aetheria",
          type: "continent",
          parent_id: nil
        })

      nation1 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Eldoria",
          type: "nation",
          parent_id: continent.id
        })

      nation2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Westmarch",
          type: "nation",
          parent_id: continent.id
        })

      city1 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Goldport",
          type: "city",
          parent_id: nation1.id
        })

      city2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Silverfall",
          type: "city",
          parent_id: nation1.id
        })

      city3 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Ironhold",
          type: "city",
          parent_id: nation2.id
        })

      {:ok,
       scope: scope,
       continent: continent,
       nation1: nation1,
       nation2: nation2,
       city1: city1,
       city2: city2,
       city3: city3}
    end

    test "location tree maintains proper hierarchical structure", %{
      scope: scope,
      continent: continent
    } do
      tree = GameMasterCore.Locations.list_locations_tree_for_game(scope)

      assert length(tree) == 1
      [continent_node] = tree
      assert continent_node.id == continent.id
      assert continent_node.name == "Aetheria"

      # Verify nations are properly sorted and nested
      assert length(continent_node.children) == 2
      [nation1_node, nation2_node] = continent_node.children
      assert nation1_node.name == "Eldoria"
      assert nation2_node.name == "Westmarch"

      # Verify cities under Eldoria
      assert length(nation1_node.children) == 2
      [city1_node, city2_node] = nation1_node.children
      assert city1_node.name == "Goldport"
      assert city2_node.name == "Silverfall"

      # Verify cities under Westmarch
      assert length(nation2_node.children) == 1
      [city3_node] = nation2_node.children
      assert city3_node.name == "Ironhold"

      # Verify all leaf nodes have empty children
      assert city1_node.children == []
      assert city2_node.children == []
      assert city3_node.children == []
    end

    test "tree ordering is consistent and alphabetical", %{scope: scope} do
      tree = GameMasterCore.Locations.list_locations_tree_for_game(scope)
      [continent_node] = tree

      # Nations should be alphabetically ordered
      nation_names = Enum.map(continent_node.children, & &1.name)
      assert nation_names == ["Eldoria", "Westmarch"]

      # Cities under Eldoria should be alphabetically ordered
      [eldoria_node | _] = continent_node.children
      city_names = Enum.map(eldoria_node.children, & &1.name)
      assert city_names == ["Goldport", "Silverfall"]
    end
  end

  describe "cross-entity link accuracy verification" do
    setup do
      scope = game_scope_fixture()
      character = character_fixture(scope, %{game_id: scope.game.id})
      note = note_fixture(scope, %{game_id: scope.game.id})
      faction = faction_fixture(scope, %{game_id: scope.game.id})
      location = location_fixture(scope, %{game_id: scope.game.id})
      quest = quest_fixture(scope, %{game_id: scope.game.id})

      # Create a complex web of relationships
      {:ok, _} = Links.link(character, note, %{relationship_type: "chronicler"})
      {:ok, _} = Links.link(character, faction, %{relationship_type: "member"})
      {:ok, _} = Links.link(character, location, %{relationship_type: "resident"})
      {:ok, _} = Links.link(character, quest, %{relationship_type: "hero"})
      {:ok, _} = Links.link(note, faction, %{relationship_type: "documentation"})
      {:ok, _} = Links.link(quest, location, %{relationship_type: "takes_place_in"})

      {:ok,
       scope: scope,
       character: character,
       note: note,
       faction: faction,
       location: location,
       quest: quest}
    end

    test "character links return all expected entity types", %{
      character: character,
      note: note,
      faction: faction,
      location: location,
      quest: quest
    } do
      links = Links.links_for(character)

      # Verify all expected links exist
      assert length(links.notes) == 1
      assert length(links.factions) == 1
      assert length(links.locations) == 1
      assert length(links.quests) == 1
      assert length(links.characters) == 0

      # Verify correct entities are linked
      assert List.first(links.notes).entity.id == note.id
      assert List.first(links.factions).entity.id == faction.id
      assert List.first(links.locations).entity.id == location.id
      assert List.first(links.quests).entity.id == quest.id

      # Verify relationship types are preserved
      assert List.first(links.notes).relationship_type == "chronicler"
      assert List.first(links.factions).relationship_type == "member"
      assert List.first(links.locations).relationship_type == "resident"
      assert List.first(links.quests).relationship_type == "hero"
    end

    test "bidirectional link consistency", %{
      character: character,
      note: note,
      faction: faction
    } do
      # Check character -> note
      character_links = Links.links_for(character)
      note_link = List.first(character_links.notes)
      assert note_link.entity.id == note.id
      assert note_link.relationship_type == "chronicler"

      # Check note -> character (should have same relationship data)
      note_links = Links.links_for(note)
      character_link = List.first(note_links.characters)
      assert character_link.entity.id == character.id
      assert character_link.relationship_type == "chronicler"

      # Check note -> faction
      faction_link = List.first(note_links.factions)
      assert faction_link.entity.id == faction.id
      assert faction_link.relationship_type == "documentation"
    end

    test "link isolation - removing one link doesn't affect others", %{
      character: character,
      note: note,
      faction: faction
    } do
      # Remove character-note link
      assert {:ok, _} = Links.unlink(character, note)

      # Verify character-note link is gone
      refute Links.linked?(character, note)

      # Verify other links remain intact
      assert Links.linked?(character, faction)
      assert Links.linked?(note, faction)

      character_links = Links.links_for(character)
      assert length(character_links.notes) == 0
      assert length(character_links.factions) == 1
    end
  end
end
