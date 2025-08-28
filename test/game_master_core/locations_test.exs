defmodule GameMasterCore.LocationsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Locations

  describe "locations" do
    alias GameMasterCore.Locations.Location
    alias GameMasterCore.Accounts.Scope

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures
    import GameMasterCore.GamesFixtures

    @invalid_attrs %{name: nil, type: nil, description: nil}
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
        description: "some description",
        game_id: game.id
      }

      assert {:ok, %Location{} = location} = Locations.create_location(scope, valid_attrs)
      assert location.name == "some name"
      assert location.type == "city"
      assert location.description == "some description"
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
        description: "some updated description"
      }

      assert {:ok, %Location{} = location} =
               Locations.update_location(scope, location, update_attrs)

      assert location.name == "some updated name"
      assert location.type == "settlement"
      assert location.description == "some updated description"
    end

    test "update_location/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      location = location_fixture(scope)

      assert_raise MatchError, fn ->
        Locations.update_location(other_scope, location, %{})
      end
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

    test "delete_location/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      location = location_fixture(scope)
      assert_raise MatchError, fn -> Locations.delete_location(other_scope, location) end
    end

    test "change_location/2 returns a location changeset" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      assert %Ecto.Changeset{} = Locations.change_location(scope, location)
    end
  end

  describe "location - character links" do
    alias GameMasterCore.Accounts.Scope

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

      assert {:error, :location_not_found} = Locations.link_character(scope, 999, character.id)
    end

    test "link_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :character_not_found} = Locations.link_character(scope, location.id, 999)
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

      assert {:error, :location_not_found} = Locations.unlink_character(scope, 999, character.id)
    end

    test "unlink_character/3 with invalid character_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :character_not_found} = Locations.unlink_character(scope, location.id, 999)
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

      refute Locations.character_linked?(scope, 999, character.id)
    end

    test "character_linked?/3 with invalid character_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      refute Locations.character_linked?(scope, location.id, 999)
    end

    test "linked_characters/2 returns all characters linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      character1 = character_fixture(scope)
      character2 = character_fixture(scope)
      unlinked_character = character_fixture(scope)

      {:ok, _} = Locations.link_character(scope, location.id, character1.id)
      {:ok, _} = Locations.link_character(scope, location.id, character2.id)

      linked_characters = Locations.linked_characters(scope, location.id)
      assert length(linked_characters) == 2
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

      assert Locations.linked_characters(scope, 999) == []
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
    alias GameMasterCore.Accounts.Scope

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

      assert {:error, :location_not_found} = Locations.link_note(scope, 999, note.id)
    end

    test "link_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :note_not_found} = Locations.link_note(scope, location.id, 999)
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

      assert {:error, :location_not_found} = Locations.unlink_note(scope, 999, note.id)
    end

    test "unlink_note/3 with invalid note_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :note_not_found} = Locations.unlink_note(scope, location.id, 999)
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

      refute Locations.note_linked?(scope, 999, note.id)
    end

    test "note_linked?/3 with invalid note_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      refute Locations.note_linked?(scope, location.id, 999)
    end

    test "linked_notes/2 returns all notes linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      note1 = note_fixture(scope)
      note2 = note_fixture(scope)
      unlinked_note = note_fixture(scope)

      {:ok, _} = Locations.link_note(scope, location.id, note1.id)
      {:ok, _} = Locations.link_note(scope, location.id, note2.id)

      linked_notes = Locations.linked_notes(scope, location.id)
      assert length(linked_notes) == 2
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

      assert Locations.linked_notes(scope, 999) == []
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
    alias GameMasterCore.Accounts.Scope

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

      assert {:error, :location_not_found} = Locations.link_faction(scope, 999, faction.id)
    end

    test "link_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :faction_not_found} = Locations.link_faction(scope, location.id, 999)
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

      assert {:error, :location_not_found} = Locations.unlink_faction(scope, 999, faction.id)
    end

    test "unlink_faction/3 with invalid faction_id returns error" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      assert {:error, :faction_not_found} = Locations.unlink_faction(scope, location.id, 999)
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

      refute Locations.faction_linked?(scope, 999, faction.id)
    end

    test "faction_linked?/3 with invalid faction_id returns false" do
      scope = user_scope_fixture()
      location = location_fixture(scope)

      refute Locations.faction_linked?(scope, location.id, 999)
    end

    test "linked_factions/2 returns all factions linked to a location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      faction1 = faction_fixture(scope)
      faction2 = faction_fixture(scope)
      unlinked_faction = faction_fixture(scope)

      {:ok, _} = Locations.link_faction(scope, location.id, faction1.id)
      {:ok, _} = Locations.link_faction(scope, location.id, faction2.id)

      linked_factions = Locations.linked_factions(scope, location.id)
      assert length(linked_factions) == 2
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

      assert Locations.linked_factions(scope, 999) == []
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
end
