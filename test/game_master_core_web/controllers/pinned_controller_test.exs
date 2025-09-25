defmodule GameMasterCoreWeb.PinnedControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.CharactersFixtures
  import GameMasterCore.NotesFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.AccountsFixtures

  alias GameMasterCore.Characters
  alias GameMasterCore.Notes
  alias GameMasterCore.Factions
  alias GameMasterCore.Locations
  alias GameMasterCore.Quests

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, game: game}
  end

  describe "index" do
    test "returns empty pinned entities when none are pinned", %{conn: conn, game: game} do
      conn = get(conn, ~p"/api/games/#{game.id}/pinned")
      response = json_response(conn, 200)

      assert response["data"]["game_id"] == game.id
      assert response["data"]["total_count"] == 0
      assert response["data"]["pinned_entities"]["characters"] == []
      assert response["data"]["pinned_entities"]["notes"] == []
      assert response["data"]["pinned_entities"]["factions"] == []
      assert response["data"]["pinned_entities"]["locations"] == []
      assert response["data"]["pinned_entities"]["quests"] == []
    end

    test "returns all pinned entities across different types", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Update scope with game for quest creation
      game_scope = %{scope | game: game}

      # Create entities
      character = character_fixture(scope, %{game_id: game.id})
      note = note_fixture(scope, %{game_id: game.id})
      faction = faction_fixture(scope, %{game_id: game.id})
      location = location_fixture(scope, %{game_id: game.id})

      {:ok, quest} =
        Quests.create_quest_for_game(game_scope, %{name: "Test Quest", content: "Test content"})

      # Pin entities
      {:ok, _} = Characters.pin_character(game_scope, character)
      {:ok, _} = Notes.pin_note(game_scope, note)
      {:ok, _} = Factions.pin_faction(game_scope, faction)
      {:ok, _} = Locations.pin_location(game_scope, location)
      {:ok, _} = Quests.pin_quest(game_scope, quest)

      conn = get(conn, ~p"/api/games/#{game.id}/pinned")
      response = json_response(conn, 200)

      assert response["data"]["game_id"] == game.id
      assert response["data"]["total_count"] == 5

      pinned_entities = response["data"]["pinned_entities"]
      assert length(pinned_entities["characters"]) == 1
      assert length(pinned_entities["notes"]) == 1
      assert length(pinned_entities["factions"]) == 1
      assert length(pinned_entities["locations"]) == 1
      assert length(pinned_entities["quests"]) == 1

      # Verify specific entity data includes pinned field
      character_data = List.first(pinned_entities["characters"])
      assert character_data["id"] == character.id
      assert character_data["pinned"] == true

      note_data = List.first(pinned_entities["notes"])
      assert note_data["id"] == note.id
      assert note_data["pinned"] == true

      faction_data = List.first(pinned_entities["factions"])
      assert faction_data["id"] == faction.id
      assert faction_data["pinned"] == true

      location_data = List.first(pinned_entities["locations"])
      assert location_data["id"] == location.id
      assert location_data["pinned"] == true

      quest_data = List.first(pinned_entities["quests"])
      assert quest_data["id"] == quest.id
      assert quest_data["pinned"] == true
    end

    test "only returns pinned entities, not unpinned ones", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Create two characters
      pinned_character = character_fixture(scope, %{game_id: game.id})
      _unpinned_character = character_fixture(scope, %{game_id: game.id})

      # Pin only one
      {:ok, _} = Characters.pin_character(scope, pinned_character)

      conn = get(conn, ~p"/api/games/#{game.id}/pinned")
      response = json_response(conn, 200)

      assert response["data"]["total_count"] == 1
      assert length(response["data"]["pinned_entities"]["characters"]) == 1

      character_data = List.first(response["data"]["pinned_entities"]["characters"])
      assert character_data["id"] == pinned_character.id
    end

    test "denies access to pinned entities for games user cannot access", %{
      conn: conn,
      scope: _scope
    } do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn = get(conn, ~p"/api/games/#{other_game.id}/pinned")
      assert response(conn, 404)
    end

    test "returns mixed pinned and unpinned counts correctly", %{
      conn: conn,
      game: game,
      scope: scope
    } do
      # Create multiple entities of same type
      character1 = character_fixture(scope, %{game_id: game.id})
      character2 = character_fixture(scope, %{game_id: game.id})
      character3 = character_fixture(scope, %{game_id: game.id})

      # Pin only two of them
      {:ok, _} = Characters.pin_character(scope, character1)
      {:ok, _} = Characters.pin_character(scope, character3)

      conn = get(conn, ~p"/api/games/#{game.id}/pinned")
      response = json_response(conn, 200)

      assert response["data"]["total_count"] == 2
      assert length(response["data"]["pinned_entities"]["characters"]) == 2

      # Verify we got the right characters
      character_ids = Enum.map(response["data"]["pinned_entities"]["characters"], & &1["id"])
      assert character1.id in character_ids
      assert character3.id in character_ids
      refute character2.id in character_ids
    end
  end
end
