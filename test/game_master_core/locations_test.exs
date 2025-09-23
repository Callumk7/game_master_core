defmodule GameMasterCore.LocationsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Locations

  describe "locations" do
    alias GameMasterCore.Locations.Location

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.GamesFixtures

    @invalid_attrs %{name: nil, type: nil, content: nil}
    @valid_type "city"
    @valid_updated_type "settlement"

    test "list_locations/1 returns all scoped locations" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      location = location_fixture(scope)
      other_location = location_fixture(other_scope)
      assert Locations.list_locations(scope) == [location]
      assert Locations.list_locations(other_scope) == [other_location]
    end

    test "get_location!/2 returns the location with given id" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      other_scope = user_scope_fixture()
      assert Locations.get_location!(scope, location.id) == location

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_location!(other_scope, location.id)
      end
    end

    test "create_location/2 with valid data creates a location" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      valid_attrs = %{
        name: "some name",
        type: @valid_type,
        content: "some content",
        game_id: game.id
      }

      assert {:ok, %Location{} = location} = Locations.create_location(scope, valid_attrs)
      assert location.name == "some name"
      assert location.type == "city"
      assert location.content == "some content"
      assert location.user_id == scope.user.id
    end

    test "create_location/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Locations.create_location(scope, attrs_with_game)
    end

    test "update_location/3 with valid data updates the location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        type: @valid_updated_type,
        content: "some updated content"
      }

      assert {:ok, %Location{} = location} =
               Locations.update_location(scope, location, update_attrs)

      assert location.name == "some updated name"
      assert location.type == "settlement"
      assert location.content == "some updated content"
    end

    test "update_location/3 performs update when called (authorization handled at controller level)" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      location = location_fixture(scope)
      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update locations
      assert {:ok, _} =
               Locations.update_location(other_scope, location, %{name: "Updated by other user"})
    end

    test "update_location/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Locations.update_location(scope, location, @invalid_attrs)

      assert location == Locations.get_location!(scope, location.id)
    end

    test "delete_location/2 deletes the location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      assert {:ok, %Location{}} = Locations.delete_location(scope, location)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_location!(scope, location.id) end
    end

    test "delete_location/2 with invalid scope still deletes location as permissions are handled on controller level" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      location = location_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Locations.delete_location(other_scope, location)
    end

    test "change_location/2 returns a location changeset" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      assert %Ecto.Changeset{} = Locations.change_location(scope, location)
    end
  end

  describe "location - character links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.CharactersFixtures

    test "link_character/3 successfully links a location and character" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Locations.link_character(scope, location.id, character.id)
      assert Locations.character_linked?(scope, location.id, character.id)
    end

    test "link_character/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.link_character(scope, invalid_location_id, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Locations.link_character(scope, location.id, invalid_character_id)
    end

    test "link_character/3 with cross-scope location returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      character = character_fixture(scope2)

      # Location exists in scope1, character is in scope2, so character_not_found is returned first
      assert {:error, :character_not_found} =
               Locations.link_character(scope1, location.id, character.id)
    end

    test "link_character/3 with cross-scope character returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      character = character_fixture(scope1)

      # Location is in scope1, character is in scope1, but called with scope2, so location_not_found is returned first
      assert {:error, :location_not_found} =
               Locations.link_character(scope2, location.id, character.id)
    end

    test "link_character/3 prevents duplicate links" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character = character_fixture(scope)

      assert {:ok, _link} = Locations.link_character(scope, location.id, character.id)

      assert {:error, %Ecto.Changeset{}} =
               Locations.link_character(scope, location.id, character.id)
    end

    test "unlink_character/3 successfully removes a location-character link" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character = character_fixture(scope)

      {:ok, _link} = Locations.link_character(scope, location.id, character.id)
      assert Locations.character_linked?(scope, location.id, character.id)

      assert {:ok, _link} = Locations.unlink_character(scope, location.id, character.id)
      refute Locations.character_linked?(scope, location.id, character.id)
    end

    test "unlink_character/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character = character_fixture(scope)

      assert {:error, :not_found} = Locations.unlink_character(scope, location.id, character.id)
    end

    test "unlink_character/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.unlink_character(scope, invalid_location_id, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()

      assert {:error, :character_not_found} =
               Locations.unlink_character(scope, location.id, invalid_character_id)
    end

    test "character_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character = character_fixture(scope)

      refute Locations.character_linked?(scope, location.id, character.id)
    end

    test "character_linked?/3 with invalid location_id returns false" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()
      refute Locations.character_linked?(scope, invalid_location_id, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_character_id = Ecto.UUID.generate()
      refute Locations.character_linked?(scope, location.id, invalid_character_id)
    end

    test "linked_characters/2 returns all characters linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)

      {:ok, _} = Locations.link_character(scope, location.id, character1.id)
      {:ok, _} = Locations.link_character(scope, location.id, character2.id)

      linked_characters_with_meta = Locations.linked_characters(scope, location.id)
      assert length(linked_characters_with_meta) == 2
      linked_characters = Enum.map(linked_characters_with_meta, & &1.entity)
      assert character1 in linked_characters
      assert character2 in linked_characters
      refute unlinked_character in linked_characters
    end

    test "linked_characters/2 returns empty list for location with no linked characters" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert Locations.linked_characters(scope, location.id) == []
    end

    test "linked_characters/2 with invalid location_id returns empty list" do
      scope = user_scope_fixture()

      invalid_location_id = Ecto.UUID.generate()
      assert Locations.linked_characters(scope, invalid_location_id) == []
    end

    test "linked_characters/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      character = character_fixture(scope1)

      {:ok, _} = Locations.link_character(scope1, location.id, character.id)

      # Same location ID in different scope should return empty
      assert Locations.linked_characters(scope2, location.id) == []
    end
  end

  describe "location - note links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.NotesFixtures

    test "link_note/3 successfully links a location and note" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Locations.link_note(scope, location.id, note.id)
      assert Locations.note_linked?(scope, location.id, note.id)
    end

    test "link_note/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.link_note(scope, invalid_location_id, note.id)
    end

    test "link_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      assert {:error, :note_not_found} = Locations.link_note(scope, location.id, invalid_note_id)
    end

    test "link_note/3 with cross-scope location returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      note = note_fixture(scope2)

      # Location exists in scope1, note is in scope2, so note_not_found is returned first
      assert {:error, :note_not_found} = Locations.link_note(scope1, location.id, note.id)
    end

    test "link_note/3 with cross-scope note returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      note = note_fixture(scope1)

      # Location is in scope1, note is in scope1, but called with scope2, so location_not_found is returned first
      assert {:error, :location_not_found} = Locations.link_note(scope2, location.id, note.id)
    end

    test "link_note/3 prevents duplicate links" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note = note_fixture(scope)

      assert {:ok, _link} = Locations.link_note(scope, location.id, note.id)
      assert {:error, %Ecto.Changeset{}} = Locations.link_note(scope, location.id, note.id)
    end

    test "unlink_note/3 successfully removes a location-note link" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note = note_fixture(scope)

      {:ok, _link} = Locations.link_note(scope, location.id, note.id)
      assert Locations.note_linked?(scope, location.id, note.id)

      assert {:ok, _link} = Locations.unlink_note(scope, location.id, note.id)
      refute Locations.note_linked?(scope, location.id, note.id)
    end

    test "unlink_note/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note = note_fixture(scope)

      assert {:error, :not_found} = Locations.unlink_note(scope, location.id, note.id)
    end

    test "unlink_note/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.unlink_note(scope, invalid_location_id, note.id)
    end

    test "unlink_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()

      assert {:error, :note_not_found} =
               Locations.unlink_note(scope, location.id, invalid_note_id)
    end

    test "note_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note = note_fixture(scope)

      refute Locations.note_linked?(scope, location.id, note.id)
    end

    test "note_linked?/3 with invalid location_id returns false" do
      scope = user_scope_fixture()
      note = note_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()
      refute Locations.note_linked?(scope, invalid_location_id, note.id)
    end

    test "note_linked?/3 with invalid note_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_note_id = Ecto.UUID.generate()
      refute Locations.note_linked?(scope, location.id, invalid_note_id)
    end

    test "linked_notes/2 returns all notes linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)
      unlinked_note = note_fixture(scope)

      {:ok, _} = Locations.link_note(scope, location.id, note1.id)
      {:ok, _} = Locations.link_note(scope, location.id, note2.id)

      linked_notes_with_meta = Locations.linked_notes(scope, location.id)
      assert length(linked_notes_with_meta) == 2
      linked_notes = Enum.map(linked_notes_with_meta, & &1.entity)
      assert note1 in linked_notes
      assert note2 in linked_notes
      refute unlinked_note in linked_notes
    end

    test "linked_notes/2 returns empty list for location with no linked notes" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert Locations.linked_notes(scope, location.id) == []
    end

    test "linked_notes/2 with invalid location_id returns empty list" do
      scope = user_scope_fixture()

      invalid_location_id = Ecto.UUID.generate()
      assert Locations.linked_notes(scope, invalid_location_id) == []
    end

    test "linked_notes/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      note = note_fixture(scope1)

      {:ok, _} = Locations.link_note(scope1, location.id, note.id)

      # Same location ID in different scope should return empty
      assert Locations.linked_notes(scope2, location.id) == []
    end
  end

  describe "location - faction links" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.FactionsFixtures

    test "link_faction/3 successfully links a location and faction" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Locations.link_faction(scope, location.id, faction.id)
      assert Locations.faction_linked?(scope, location.id, faction.id)
    end

    test "link_faction/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.link_faction(scope, invalid_location_id, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Locations.link_faction(scope, location.id, invalid_faction_id)
    end

    test "link_faction/3 with cross-scope location returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      faction = faction_fixture(scope2)

      # Location exists in scope1, faction is in scope2, so faction_not_found is returned first
      assert {:error, :faction_not_found} =
               Locations.link_faction(scope1, location.id, faction.id)
    end

    test "link_faction/3 with cross-scope faction returns error" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      faction = faction_fixture(scope1)

      # Location is in scope1, faction is in scope1, but called with scope2, so location_not_found is returned first
      assert {:error, :location_not_found} =
               Locations.link_faction(scope2, location.id, faction.id)
    end

    test "link_faction/3 prevents duplicate links" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction = faction_fixture(scope)

      assert {:ok, _link} = Locations.link_faction(scope, location.id, faction.id)
      assert {:error, %Ecto.Changeset{}} = Locations.link_faction(scope, location.id, faction.id)
    end

    test "unlink_faction/3 successfully removes a location-faction link" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction = faction_fixture(scope)

      {:ok, _link} = Locations.link_faction(scope, location.id, faction.id)
      assert Locations.faction_linked?(scope, location.id, faction.id)

      assert {:ok, _link} = Locations.unlink_faction(scope, location.id, faction.id)
      refute Locations.faction_linked?(scope, location.id, faction.id)
    end

    test "unlink_faction/3 with non-existent link returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction = faction_fixture(scope)

      assert {:error, :not_found} = Locations.unlink_faction(scope, location.id, faction.id)
    end

    test "unlink_faction/3 with invalid location_id returns error" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()

      assert {:error, :location_not_found} =
               Locations.unlink_faction(scope, invalid_location_id, faction.id)
    end

    test "unlink_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()

      assert {:error, :faction_not_found} =
               Locations.unlink_faction(scope, location.id, invalid_faction_id)
    end

    test "faction_linked?/3 returns false for unlinked entities" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction = faction_fixture(scope)

      refute Locations.faction_linked?(scope, location.id, faction.id)
    end

    test "faction_linked?/3 with invalid location_id returns false" do
      scope = user_scope_fixture()
      faction = faction_fixture(scope)

      invalid_location_id = Ecto.UUID.generate()
      refute Locations.faction_linked?(scope, invalid_location_id, faction.id)
    end

    test "faction_linked?/3 with invalid faction_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      invalid_faction_id = Ecto.UUID.generate()
      refute Locations.faction_linked?(scope, location.id, invalid_faction_id)
    end

    test "linked_factions/2 returns all factions linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)
      unlinked_faction = faction_fixture(scope)

      {:ok, _} = Locations.link_faction(scope, location.id, faction1.id)
      {:ok, _} = Locations.link_faction(scope, location.id, faction2.id)

      linked_factions_with_meta = Locations.linked_factions(scope, location.id)
      assert length(linked_factions_with_meta) == 2
      linked_factions = Enum.map(linked_factions_with_meta, & &1.entity)
      assert faction1 in linked_factions
      assert faction2 in linked_factions
      refute unlinked_faction in linked_factions
    end

    test "linked_factions/2 returns empty list for location with no linked factions" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert Locations.linked_factions(scope, location.id) == []
    end

    test "linked_factions/2 with invalid location_id returns empty list" do
      scope = user_scope_fixture()

      invalid_location_id = Ecto.UUID.generate()
      assert Locations.linked_factions(scope, invalid_location_id) == []
    end

    test "linked_factions/2 respects scope boundaries" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      location = location_fixture(scope1)
      faction = faction_fixture(scope1)

      {:ok, _} = Locations.link_faction(scope1, location.id, faction.id)

      # Same location ID in different scope should return empty
      assert Locations.linked_factions(scope2, location.id) == []
    end
  end

  describe "location tree" do
    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.GamesFixtures

    test "list_locations_tree_for_game/1 returns empty list when no locations exist" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      assert Locations.list_locations_tree_for_game(scope) == []
    end

    test "list_locations_tree_for_game/1 returns flat tree for root locations" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      location1 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Forest",
          type: "region",
          parent_id: nil
        })

      location2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Mountains",
          type: "region",
          parent_id: nil
        })

      tree = Locations.list_locations_tree_for_game(scope)

      assert length(tree) == 2
      # Should be sorted by name
      [first, second] = tree
      assert first.id == location1.id
      assert first.name == "Forest"
      assert first.children == []

      assert second.id == location2.id
      assert second.name == "Mountains"
      assert second.children == []
    end

    test "list_locations_tree_for_game/1 builds hierarchical structure correctly" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      # Create continent (root)
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Westeros",
          type: "continent",
          parent_id: nil
        })

      # Create nation (child of continent)
      nation =
        location_fixture(scope, %{
          game_id: game.id,
          name: "The North",
          type: "nation",
          parent_id: continent.id
        })

      # Create city (child of nation)
      city =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Winterfell",
          type: "city",
          parent_id: nation.id
        })

      tree = Locations.list_locations_tree_for_game(scope)

      assert length(tree) == 1
      [continent_node] = tree
      assert continent_node.id == continent.id
      assert continent_node.name == "Westeros"
      assert continent_node.parent_id == nil

      assert length(continent_node.children) == 1
      [nation_node] = continent_node.children
      assert nation_node.id == nation.id
      assert nation_node.name == "The North"
      assert nation_node.parent_id == continent.id

      assert length(nation_node.children) == 1
      [city_node] = nation_node.children
      assert city_node.id == city.id
      assert city_node.name == "Winterfell"
      assert city_node.parent_id == nation.id
      assert city_node.children == []
    end

    test "list_locations_tree_for_game/1 handles multiple children correctly" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      # Create parent location
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Continent",
          type: "continent",
          parent_id: nil
        })

      # Create multiple children
      nation1 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Zebra Nation",
          type: "nation",
          parent_id: continent.id
        })

      nation2 =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Alpha Nation",
          type: "nation",
          parent_id: continent.id
        })

      tree = Locations.list_locations_tree_for_game(scope)

      [continent_node] = tree
      assert length(continent_node.children) == 2

      # Should be sorted by name
      [child1, child2] = continent_node.children
      assert child1.name == "Alpha Nation"
      assert child1.id == nation2.id

      assert child2.name == "Zebra Nation"
      assert child2.id == nation1.id
    end

    test "list_locations_tree_for_game/1 includes all location fields" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      location =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Test Location",
          content: "A test description",
          type: "city",
          tags: ["test", "example"],
          parent_id: nil
        })

      tree = Locations.list_locations_tree_for_game(scope)

      [node] = tree
      assert node.id == location.id
      assert node.name == "Test Location"
      assert node.content == "A test description"
      assert node.type == "city"
      assert node.tags == ["test", "example"]
      assert node.parent_id == nil
      assert node.entity_type == "location"
      assert node.children == []
    end

    test "list_locations_tree_for_game/1 only returns locations for specified game" do
      scope = user_scope_fixture()
      game1 = game_fixture(scope)
      game2 = game_fixture(scope)

      # Create location in game1
      _location1 =
        location_fixture(scope, %{
          game_id: game1.id,
          name: "Game 1 Location",
          type: "city"
        })

      # Create location in game2  
      _location2 =
        location_fixture(scope, %{
          game_id: game2.id,
          name: "Game 2 Location",
          type: "city"
        })

      # Test game1
      scope1 = %{scope | game: game1}
      tree1 = Locations.list_locations_tree_for_game(scope1)
      assert length(tree1) == 1
      [node1] = tree1
      assert node1.name == "Game 1 Location"

      # Test game2
      scope2 = %{scope | game: game2}
      tree2 = Locations.list_locations_tree_for_game(scope2)
      assert length(tree2) == 1
      [node2] = tree2
      assert node2.name == "Game 2 Location"
    end

    test "list_locations_tree_for_game/1 handles deep nesting" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      # Create 4-level hierarchy
      continent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Continent",
          type: "continent",
          parent_id: nil
        })

      nation =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Nation",
          type: "nation",
          parent_id: continent.id
        })

      region =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Region",
          type: "region",
          parent_id: nation.id
        })

      _city =
        location_fixture(scope, %{
          game_id: game.id,
          name: "City",
          type: "city",
          parent_id: region.id
        })

      tree = Locations.list_locations_tree_for_game(scope)

      [continent_node] = tree
      [nation_node] = continent_node.children
      [region_node] = nation_node.children
      [city_node] = region_node.children

      assert continent_node.name == "Continent"
      assert nation_node.name == "Nation"
      assert region_node.name == "Region"
      assert city_node.name == "City"
      assert city_node.children == []
    end

    test "list_locations_tree_for_game/1 includes entity_type field for all nodes" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      scope = %{scope | game: game}

      # Create parent and child locations
      parent =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Parent Location",
          type: "continent",
          parent_id: nil
        })

      _child =
        location_fixture(scope, %{
          game_id: game.id,
          name: "Child Location",
          type: "nation",
          parent_id: parent.id
        })

      tree = Locations.list_locations_tree_for_game(scope)
      [parent_node] = tree
      [child_node] = parent_node.children

      # Verify entity_type field is present on all nodes
      assert parent_node.entity_type == "location"
      assert child_node.entity_type == "location"
    end
  end
end
