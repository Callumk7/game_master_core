defmodule GameMasterCore.QuestObjectivesTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Repo
  alias GameMasterCore.Quests
  alias GameMasterCore.Quests.Quest

  describe "quest-objective associations" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.ObjectivesFixtures
    import GameMasterCore.QuestsFixtures

    test "quest has_many objectives association" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective1 = objective_fixture(scope, quest)
      objective2 = objective_fixture(scope, quest, %{body: "second objective"})

      quest_with_objectives =
        Quest
        |> Repo.get!(quest.id)
        |> Repo.preload(:objectives)

      assert length(quest_with_objectives.objectives) == 2
      objective_ids = Enum.map(quest_with_objectives.objectives, & &1.id)
      assert objective1.id in objective_ids
      assert objective2.id in objective_ids
    end

    test "objective belongs_to quest association" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective = objective_fixture(scope, quest)

      objective_with_quest =
        GameMasterCore.Quests.Objective
        |> Repo.get!(objective.id)
        |> Repo.preload(:quest)

      assert objective_with_quest.quest.id == quest.id
      assert objective_with_quest.quest.name == quest.name
    end

    test "deleting quest cascades to objectives" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      objective1 = objective_fixture(scope, quest)
      objective2 = objective_fixture(scope, quest, %{body: "second objective"})

      # Verify objectives exist
      assert Repo.get(GameMasterCore.Quests.Objective, objective1.id)
      assert Repo.get(GameMasterCore.Quests.Objective, objective2.id)

      # Delete the quest
      {:ok, _deleted_quest} = Quests.delete_quest(scope, quest)

      # Verify objectives are deleted (cascade)
      assert Repo.get(GameMasterCore.Quests.Objective, objective1.id) == nil
      assert Repo.get(GameMasterCore.Quests.Objective, objective2.id) == nil
    end

    test "quest can exist without objectives" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      quest_with_objectives =
        Quest
        |> Repo.get!(quest.id)
        |> Repo.preload(:objectives)

      assert quest_with_objectives.objectives == []
    end

    test "objective requires quest_id" do
      # Try to create objective directly without quest_id
      changeset =
        GameMasterCore.Quests.Objective.changeset(%GameMasterCore.Quests.Objective{}, %{
          body: "test objective"
        })

      assert changeset.errors[:quest_id] == {"can't be blank", [validation: :required]}
    end

    test "quest tree includes objectives count (future enhancement ready)" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      _objective1 = objective_fixture(scope, quest)
      _objective2 = objective_fixture(scope, quest, %{body: "second objective"})

      # This tests that the quest tree functionality doesn't break with objectives
      tree = Quests.list_quests_tree_for_game(scope)
      assert is_list(tree)

      # Find our quest in the tree
      quest_node = Enum.find(tree, fn node -> node.id == quest.id end)
      assert quest_node != nil
      assert quest_node.name == quest.name
    end

    test "objectives maintain insertion order" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      objective1 = objective_fixture(scope, quest, %{body: "first"})
      # Ensure different timestamps
      :timer.sleep(10)
      objective2 = objective_fixture(scope, quest, %{body: "second"})
      :timer.sleep(10)
      objective3 = objective_fixture(scope, quest, %{body: "third"})

      quest_with_objectives =
        Quest
        |> Repo.get!(quest.id)
        |> Repo.preload(
          objectives: from(o in GameMasterCore.Quests.Objective, order_by: [asc: o.inserted_at])
        )

      objectives = quest_with_objectives.objectives
      assert length(objectives) == 3
      assert Enum.at(objectives, 0).id == objective1.id
      assert Enum.at(objectives, 1).id == objective2.id
      assert Enum.at(objectives, 2).id == objective3.id
    end
  end

  describe "quest-objective database constraints" do
    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.QuestsFixtures

    test "objective quest_id foreign key constraint" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      # Create objective
      {:ok, objective} =
        Repo.insert(%GameMasterCore.Quests.Objective{
          id: Ecto.UUID.generate(),
          body: "test objective",
          quest_id: quest.id
        })

      # Verify it exists
      assert Repo.get(GameMasterCore.Quests.Objective, objective.id)

      # Delete quest directly from database to test constraint
      Repo.delete_all(from q in Quest, where: q.id == ^quest.id)

      # Objective should be deleted due to cascade
      assert Repo.get(GameMasterCore.Quests.Objective, objective.id) == nil
    end

    test "objective note_link_id foreign key constraint allows nil" do
      scope = game_scope_fixture()
      quest = quest_fixture(scope)

      # Create objective without note link
      {:ok, objective} =
        Repo.insert(%GameMasterCore.Quests.Objective{
          id: Ecto.UUID.generate(),
          body: "test objective",
          quest_id: quest.id,
          note_link_id: nil
        })

      assert objective.note_link_id == nil
    end

    test "objective note_link_id foreign key constraint with valid note" do
      import GameMasterCore.NotesFixtures

      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      # Create objective with note link
      {:ok, objective} =
        Repo.insert(%GameMasterCore.Quests.Objective{
          id: Ecto.UUID.generate(),
          body: "test objective",
          quest_id: quest.id,
          note_link_id: note.id
        })

      assert objective.note_link_id == note.id
    end

    test "objective note_link_id nullified when note is deleted" do
      import GameMasterCore.NotesFixtures

      scope = game_scope_fixture()
      quest = quest_fixture(scope)
      note = note_fixture(scope)

      # Create objective with note link
      {:ok, objective} =
        Repo.insert(%GameMasterCore.Quests.Objective{
          id: Ecto.UUID.generate(),
          body: "test objective",
          quest_id: quest.id,
          note_link_id: note.id
        })

      assert objective.note_link_id == note.id

      # Delete note
      Repo.delete(note)

      # Objective should have note_link_id set to nil
      updated_objective = Repo.get(GameMasterCore.Quests.Objective, objective.id)
      assert updated_objective.note_link_id == nil
    end
  end
end
