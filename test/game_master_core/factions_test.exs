defmodule GameMasterCore.FactionsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Factions

  describe "factions" do
    alias GameMasterCore.Factions.Faction

    import GameMasterCore.AccountsFixtures, only: [game_scope_fixture: 0]
    import GameMasterCore.FactionsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_factions/1 returns all scoped factions" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      faction = faction_fixture(scope)
      other_faction = faction_fixture(other_scope)
      assert Factions.list_factions(scope) == [faction]
      assert Factions.list_factions(other_scope) == [other_faction]
    end

    test "get_faction!/2 returns the faction with given id" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      other_scope = game_scope_fixture()
      assert Factions.get_faction!(scope, faction.id) == faction
      assert_raise Ecto.NoResultsError, fn -> Factions.get_faction!(other_scope, faction.id) end
    end

    test "create_faction/2 with valid data creates a faction" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = game_scope_fixture()

      assert {:ok, %Faction{} = faction} = Factions.create_faction(scope, valid_attrs)
      assert faction.name == "some name"
      assert faction.description == "some description"
      assert faction.game_id == scope.game.id
    end

    test "create_faction/2 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Factions.create_faction(scope, @invalid_attrs)
    end

    test "update_faction/3 with valid data updates the faction" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Faction{} = faction} = Factions.update_faction(scope, faction, update_attrs)
      assert faction.name == "some updated name"
      assert faction.description == "some updated description"
    end

    test "update_faction/3 with invalid scope raises" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      faction = faction_fixture(scope)

      assert_raise MatchError, fn ->
        Factions.update_faction(other_scope, faction, %{})
      end
    end

    test "update_faction/3 with invalid data returns error changeset" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Factions.update_faction(scope, faction, @invalid_attrs)
      assert faction == Factions.get_faction!(scope, faction.id)
    end

    test "delete_faction/2 deletes the faction" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      assert {:ok, %Faction{}} = Factions.delete_faction(scope, faction)
      assert_raise Ecto.NoResultsError, fn -> Factions.get_faction!(scope, faction.id) end
    end

    test "delete_faction/2 with invalid scope raises" do
      scope = game_scope_fixture()
      other_scope = game_scope_fixture()
      faction = faction_fixture(scope)
      assert_raise MatchError, fn -> Factions.delete_faction(other_scope, faction) end
    end

    test "change_faction/2 returns a faction changeset" do
      scope = game_scope_fixture()
      faction = faction_fixture(scope)
      assert %Ecto.Changeset{} = Factions.change_faction(scope, faction)
    end
  end
end
