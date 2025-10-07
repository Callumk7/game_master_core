defmodule GameMasterCoreWeb.ObjectiveControllerTest do
  use GameMasterCoreWeb.ConnCase

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.ObjectivesFixtures
  import GameMasterCore.QuestsFixtures
  import GameMasterCore.GamesFixtures



  @create_attrs %{
    body: "some objective body",
    complete: false
  }
  @update_attrs %{
    body: "updated objective body",
    complete: true
  }
  @invalid_attrs %{body: nil}

  setup :register_and_log_in_user

  setup %{conn: conn, user: user, scope: scope} do
    game = game_fixture(scope)
    game_scope = GameMasterCore.Accounts.Scope.put_game(scope, game)
    quest = quest_fixture(game_scope)
    conn = authenticate_api_user(conn, user)

    {:ok, conn: conn, scope: game_scope, game: game, quest: quest}
  end

  describe "index" do
    test "lists all objectives for a quest", %{conn: conn, scope: scope, game: game, quest: quest} do
      objective1 = objective_fixture(scope, quest)
      objective2 = objective_fixture(scope, quest, %{body: "second objective"})

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives")
      assert json_response(conn, 200)["data"] |> length() == 2

      response_data = json_response(conn, 200)["data"]
      objective_ids = Enum.map(response_data, & &1["id"])
      assert objective1.id in objective_ids
      assert objective2.id in objective_ids
    end

    test "returns empty list when quest has no objectives", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives")
      assert json_response(conn, 200)["data"] == []
    end

    test "returns 404 for non-existent quest", %{conn: conn, game: game} do
      fake_quest_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game}/quests/#{fake_quest_id}/objectives")
      assert json_response(conn, 404)
    end
  end

  describe "create objective" do
    test "renders objective when data is valid", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      conn =
        post(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives", objective: @create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{id}")

      assert %{
               "id" => ^id,
               "body" => "some objective body",
               "complete" => false,
               "quest_id" => quest_id
             } = json_response(conn, 200)["data"]

      assert quest_id == quest.id
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      conn =
        post(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives", objective: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 404 for non-existent quest", %{conn: conn, game: game} do
      fake_quest_id = Ecto.UUID.generate()

      conn =
        post(conn, ~p"/api/games/#{game}/quests/#{fake_quest_id}/objectives",
          objective: @create_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "show objective" do
    test "renders objective", %{conn: conn, scope: scope, game: game, quest: quest} do
      objective = objective_fixture(scope, quest)
      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}")

      assert %{
               "id" => id,
               "body" => "some objective body",
               "complete" => false
             } = json_response(conn, 200)["data"]

      assert id == objective.id
    end

    test "returns 404 for non-existent objective", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      fake_id = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{fake_id}")
      assert json_response(conn, 404)
    end

    test "returns 404 for objective in different quest", %{
      conn: conn,
      scope: scope,
      game: game,
      quest: quest
    } do
      other_quest = quest_fixture(scope)
      objective = objective_fixture(scope, other_quest)

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}")
      assert json_response(conn, 404)
    end
  end

  describe "update objective" do
    test "renders objective when data is valid", %{
      conn: conn,
      scope: scope,
      game: game,
      quest: quest
    } do
      objective = objective_fixture(scope, quest)

      conn =
        put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}",
          objective: @update_attrs
        )

      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{id}")

      assert %{
               "id" => ^id,
               "body" => "updated objective body",
               "complete" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      scope: scope,
      game: game,
      quest: quest
    } do
      objective = objective_fixture(scope, quest)

      conn =
        put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}",
          objective: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 404 for non-existent objective", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      fake_id = Ecto.UUID.generate()

      conn =
        put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{fake_id}",
          objective: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete objective" do
    test "deletes chosen objective", %{conn: conn, scope: scope, game: game, quest: quest} do
      objective = objective_fixture(scope, quest)

      conn = delete(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}")
      assert response(conn, 204)

      conn = get(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}")
      assert json_response(conn, 404)
    end

    test "returns 404 for non-existent objective", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      fake_id = Ecto.UUID.generate()
      conn = delete(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{fake_id}")
      assert json_response(conn, 404)
    end
  end

  describe "complete objective" do
    test "marks objective as complete", %{conn: conn, scope: scope, game: game, quest: quest} do
      objective = objective_fixture(scope, quest, %{complete: false})

      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}/complete")
      assert %{"complete" => true} = json_response(conn, 200)["data"]
    end

    test "returns 404 for non-existent objective", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      fake_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{fake_id}/complete")
      assert json_response(conn, 404)
    end
  end

  describe "uncomplete objective" do
    test "marks objective as incomplete", %{conn: conn, scope: scope, game: game, quest: quest} do
      objective = objective_fixture(scope, quest, %{complete: true})

      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}/uncomplete")
      assert %{"complete" => false} = json_response(conn, 200)["data"]
    end

    test "returns 404 for non-existent objective", %{
      conn: conn,
      scope: _scope,
      game: game,
      quest: quest
    } do
      fake_id = Ecto.UUID.generate()
      conn = put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{fake_id}/uncomplete")
      assert json_response(conn, 404)
    end
  end

  describe "objective with note link" do
    test "creates objective with note link", %{conn: conn, scope: scope, game: game, quest: quest} do
      import GameMasterCore.NotesFixtures
      note = note_fixture(scope)

      attrs = Map.put(@create_attrs, :note_link_id, note.id)
      conn = post(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives", objective: attrs)

      assert %{"note_link_id" => note_link_id} = json_response(conn, 201)["data"]
      assert note_link_id == note.id
    end

    test "updates objective with note link", %{conn: conn, scope: scope, game: game, quest: quest} do
      import GameMasterCore.NotesFixtures
      note = note_fixture(scope)
      objective = objective_fixture(scope, quest)

      attrs = Map.put(@update_attrs, :note_link_id, note.id)

      conn =
        put(conn, ~p"/api/games/#{game}/quests/#{quest}/objectives/#{objective}",
          objective: attrs
        )

      assert %{"note_link_id" => note_link_id} = json_response(conn, 200)["data"]
      assert note_link_id == note.id
    end
  end

  describe "authorization" do
    test "cannot access objectives from different game", %{scope: scope, quest: quest} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)
      objective = objective_fixture(scope, quest)

      # Try to access objective from different game
      conn =
        get(build_conn(), ~p"/api/games/#{other_game}/quests/#{quest}/objectives/#{objective}")

      assert json_response(conn, 401)
    end

    test "cannot create objective in quest from different game", %{scope: _scope, quest: quest} do
      other_user_scope = user_scope_fixture()
      other_game = game_fixture(other_user_scope)

      conn =
        post(build_conn(), ~p"/api/games/#{other_game}/quests/#{quest}/objectives",
          objective: @create_attrs
        )

      assert json_response(conn, 401)
    end
  end
end
