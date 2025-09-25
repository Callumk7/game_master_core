defmodule GameMasterCoreWeb.CharacterPrimaryFactionTest do
  use GameMasterCoreWeb.ConnCase
  import GameMasterCore.GamesFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.FactionsFixtures

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    conn = authenticate_api_user(conn, user)
    {:ok, conn: conn, user: user, scope: scope, game: game}
  end

  describe "get_primary_faction/2" do
    test "returns primary faction when character has one", %{conn: conn, scope: scope, game: game} do
      faction = faction_fixture(scope, %{game_id: game.id})

      character =
        character_fixture(scope, %{
          game_id: game.id,
          member_of_faction_id: faction.id,
          faction_role: "Captain"
        })

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
               "data" => %{
                 "id" => character_id,
                 "member_of_faction_id" => faction_id,
                 "faction_role" => "Captain"
               }
             } = json_response(conn, 200)

      assert character_id == character.id
      assert faction_id == faction.id

      # Verify CharacterFaction record was created
      character_faction =
        GameMasterCore.Repo.get_by(
          GameMasterCore.Characters.CharacterFaction,
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
      faction = faction_fixture(scope, %{game_id: game.id})

      character =
        character_fixture(scope, %{
          game_id: game.id,
          member_of_faction_id: faction.id,
          faction_role: "Captain"
        })

      conn = delete(conn, ~p"/api/games/#{game.id}/characters/#{character.id}/primary-faction")

      assert %{
               "data" => %{
                 "member_of_faction_id" => nil,
                 "faction_role" => nil
               }
             } = json_response(conn, 200)
    end
  end
end
