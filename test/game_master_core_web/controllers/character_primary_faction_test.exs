defmodule GameMasterCoreWeb.CharacterPrimaryFactionTest do
  use GameMasterCoreWeb.ConnCase
  import GameMasterCore.GamesFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.FactionsFixtures

  alias GameMasterCore.Characters
  alias GameMasterCore.Characters.CharacterFaction

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)
    {:ok, conn: conn, user: user, scope: scope, game: game}
  end

  describe "get_primary_faction/2" do
    test "returns primary faction when character has one", %{conn: conn, scope: scope, game: game} do
      # Create a scope with the game information
      game_scope = %{scope | game: game}

      faction = faction_fixture(game_scope, %{game_id: game.id})
      character = character_fixture(game_scope, %{game_id: game.id})

      # Set primary faction using the new approach
      {:ok, _} = Characters.set_primary_faction(game_scope, character, faction.id, "Captain")

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/primary-faction")

      assert %{
               "data" => %{
                 "character_id" => character_id,
                 "faction" => faction_data,
                 "role" => "Captain"
               }
             } = json_response(conn, 200)

      assert character_id == character.id
      assert faction_data["id"] == faction.id
    end

    test "returns 404 when character has no primary faction", %{
      conn: conn,
      scope: scope,
      game: game
    } do
      character = character_fixture(scope, %{game_id: game.id})

      conn = get(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/primary-faction")

      assert %{"error" => "No primary faction set for this character"} = json_response(conn, 404)
    end
  end

  describe "set_primary_faction/2" do
    test "sets primary faction and creates CharacterFaction record", %{
      conn: conn,
      scope: scope,
      game: game
    } do
      faction = faction_fixture(scope, %{game_id: game.id})
      character = character_fixture(scope, %{game_id: game.id})

      conn =
        post(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/primary-faction", %{
          "faction_id" => faction.id,
          "role" => "Captain"
        })

      assert %{
               "data" => character_data
             } = json_response(conn, 200)

      # Verify character data no longer includes the old fields
      assert character_data["id"] == character.id
      refute Map.has_key?(character_data, "member_of_faction_id")
      refute Map.has_key?(character_data, "faction_role")

      # Verify CharacterFaction record was created
      character_faction =
        GameMasterCore.Repo.get_by(
          CharacterFaction,
          character_id: character.id,
          faction_id: faction.id
        )

      assert character_faction != nil
      assert character_faction.relationship_type == "Captain"
      assert character_faction.is_active == true
    end
  end

  describe "remove_primary_faction/2" do
    test "removes primary faction", %{conn: conn, scope: scope, game: game} do
      # Create a scope with the game information
      game_scope = %{scope | game: game}

      faction = faction_fixture(game_scope, %{game_id: game.id})
      character = character_fixture(game_scope, %{game_id: game.id})

      # Set primary faction first
      {:ok, _} = Characters.set_primary_faction(game_scope, character, faction.id, "Captain")

      conn = delete(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/primary-faction")

      assert %{
               "data" => character_data
             } = json_response(conn, 200)

      # Verify the old fields are no longer in the response
      refute Map.has_key?(character_data, "member_of_faction_id")
      refute Map.has_key?(character_data, "faction_role")
    end
  end
end
