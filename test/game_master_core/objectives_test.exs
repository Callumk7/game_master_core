defmodule GameMasterCore.ObjectivesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Objectives
  alias GameMasterCore.Quests.Objective

  describe "objectives" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.ObjectivesFixtures
    import GameMasterCore.QuestsFixtures
    import GameMasterCore.NotesFixtures

    @invalid_attrs %{body: nil}

    test "list_objectives_for_quest/2 returns all objectives for a quest" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective1 = objective_fixture(scope, quest)
      objective2 = objective_fixture(scope, quest, %{body: "second objective"})

      # Different quest should not return these objectives
      other_quest = quest_fixture(scope)
      _other_objective = objective_fixture(scope, other_quest)

      assert {:ok, objectives} = Objectives.list_objectives_for_quest(scope, quest.id)
      assert length(objectives) == 2
      assert Enum.any?(objectives, &(&1.id == objective1.id))
      assert Enum.any?(objectives, &(&1.id == objective2.id))
    end

    test "list_objectives_for_quest/2 returns error for invalid quest" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(other_scope)

      assert {:error, :not_found} = Objectives.list_objectives_for_quest(scope, quest.id)
    end

    test "get_objective_for_quest!/3 returns the objective with given id" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)

      result = Objectives.get_objective_for_quest!(scope, quest.id, objective.id)
      assert result.id == objective.id
    end

    test "get_objective_for_quest!/3 raises for invalid quest" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(other_scope)
      objective = objective_fixture(other_scope, quest)

      assert_raise Ecto.NoResultsError, fn ->
        Objectives.get_objective_for_quest!(scope, quest.id, objective.id)
      end
    end

    test "fetch_objective_for_quest/3 returns {:ok, objective} when found" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)

      assert {:ok, result} = Objectives.fetch_objective_for_quest(scope, quest.id, objective.id)
      assert result.id == objective.id
    end

    test "fetch_objective_for_quest/3 returns {:error, :not_found} when not found" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      fake_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Objectives.fetch_objective_for_quest(scope, quest.id, fake_id)
    end

    test "fetch_objective_for_quest/3 returns {:error, :not_found} for invalid quest" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(other_scope)
      objective = objective_fixture(other_scope, quest)

      assert {:error, :not_found} =
               Objectives.fetch_objective_for_quest(scope, quest.id, objective.id)
    end

    test "create_objective_for_quest/3 with valid data creates an objective" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      valid_attrs = %{body: "some objective body", complete: false}

      assert {:ok, %Objective{} = objective} =
               Objectives.create_objective_for_quest(scope, quest.id, valid_attrs)

      assert objective.body == "some objective body"
      assert objective.complete == false
      assert objective.quest_id == quest.id
    end

    test "create_objective_for_quest/3 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Objectives.create_objective_for_quest(scope, quest.id, @invalid_attrs)
    end

    test "create_objective_for_quest/3 with invalid quest returns error" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      quest = quest_fixture(other_scope)
      valid_attrs = %{body: "some objective body"}

      assert {:error, :not_found} =
               Objectives.create_objective_for_quest(scope, quest.id, valid_attrs)
    end

    test "create_objective_for_quest/3 with note link creates objective" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)
      valid_attrs = %{body: "objective with note", note_link_id: note.id}

      assert {:ok, %Objective{} = objective} =
               Objectives.create_objective_for_quest(scope, quest.id, valid_attrs)

      assert objective.note_link_id == note.id
    end

    test "update_objective_for_quest/4 with valid data updates the objective" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)
      update_attrs = %{body: "updated objective body", complete: true}

      assert {:ok, %Objective{} = updated_objective} =
               Objectives.update_objective_for_quest(scope, quest.id, objective.id, update_attrs)

      assert updated_objective.body == "updated objective body"
      assert updated_objective.complete == true
    end

    test "update_objective_for_quest/4 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)

      assert {:error, %Ecto.Changeset{}} =
               Objectives.update_objective_for_quest(
                 scope,
                 quest.id,
                 objective.id,
                 @invalid_attrs
               )
    end

    test "delete_objective_for_quest/3 deletes the objective" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)

      assert {:ok, %Objective{}} =
               Objectives.delete_objective_for_quest(scope, quest.id, objective.id)

      assert {:error, :not_found} =
               Objectives.fetch_objective_for_quest(scope, quest.id, objective.id)
    end

    test "change_objective/1 returns an objective changeset" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)
      assert %Ecto.Changeset{} = Objectives.change_objective(objective)
    end

    test "complete_objective/3 marks objective as complete" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest, %{complete: false})

      assert {:ok, %Objective{} = updated_objective} =
               Objectives.complete_objective(scope, quest.id, objective.id)

      assert updated_objective.complete == true
    end

    test "uncomplete_objective/3 marks objective as incomplete" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest, %{complete: true})

      assert {:ok, %Objective{} = updated_objective} =
               Objectives.uncomplete_objective(scope, quest.id, objective.id)

      assert updated_objective.complete == false
    end

    test "list_objectives_for_game/1 returns all objectives for a game" do
      scope = game_scope_fixture()
      quest1 = quest_fixture(scope)
      quest2 = quest_fixture(scope)
      objective1 = objective_fixture(scope, quest1)
      objective2 = objective_fixture(scope, quest2)

      # Different game should not return these objectives
      other_scope = game_scope_fixture()
      other_quest = quest_fixture(other_scope)
      _other_objective = objective_fixture(other_scope, other_quest)

      objectives = Objectives.list_objectives_for_game(scope)
      assert length(objectives) == 2
      assert Enum.any?(objectives, &(&1.id == objective1.id))
      assert Enum.any?(objectives, &(&1.id == objective2.id))

      # Check that quest is preloaded
      first_objective = Enum.find(objectives, &(&1.id == objective1.id))
      assert first_objective.quest.id == quest1.id
    end

    test "objectives are ordered by insertion time" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      objective1 = objective_fixture(scope, quest, %{body: "first"})
      # Ensure different timestamps
      :timer.sleep(10)
      objective2 = objective_fixture(scope, quest, %{body: "second"})

      assert {:ok, objectives} = Objectives.list_objectives_for_quest(scope, quest.id)
      assert [first, second] = objectives
      assert first.id == objective1.id
      assert second.id == objective2.id
    end
  end

  describe "objective validations" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures

    test "body is required" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert {:error, changeset} =
               Objectives.create_objective_for_quest(scope, quest.id, %{body: nil})

      assert "can't be blank" in errors_on(changeset).body
    end

    test "body must be at least 1 character" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      assert {:error, changeset} =
               Objectives.create_objective_for_quest(scope, quest.id, %{body: ""})

      assert "can't be blank" in errors_on(changeset).body
    end

    test "body cannot exceed 1000 characters" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      long_body = String.duplicate("a", 1001)

      assert {:error, changeset} =
               Objectives.create_objective_for_quest(scope, quest.id, %{body: long_body})

      assert "should be at most 1000 character(s)" in errors_on(changeset).body
    end

    test "quest_id foreign key constraint" do
      scope = game_scope_fixture()
      fake_quest_id = Ecto.UUID.generate()

      # This should fail at the context level, not the database level
      assert {:error, :not_found} =
               Objectives.create_objective_for_quest(scope, fake_quest_id, %{body: "test"})
    end

    test "note_link_id foreign key constraint" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      fake_note_id = Ecto.UUID.generate()

      # This should succeed creation but fail on constraint validation if the note doesn't exist
      assert {:error, changeset} =
               Objectives.create_objective_for_quest(scope, quest.id, %{
                 body: "test",
                 note_link_id: fake_note_id
               })

      assert "does not exist" in errors_on(changeset).note_link_id
    end
  end
end
