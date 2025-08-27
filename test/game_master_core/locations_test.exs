defmodule GameMasterCore.LocationsTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Locations

  describe "locations" do
    alias GameMasterCore.Locations.Location

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.LocationsFixtures

    @invalid_attrs %{name: nil, type: nil, description: nil}

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
      assert_raise Ecto.NoResultsError, fn -> Locations.get_location!(other_scope, location.id) end
    end

    test "create_location/2 with valid data creates a location" do
      valid_attrs = %{name: "some name", type: "some type", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %Location{} = location} = Locations.create_location(scope, valid_attrs)
      assert location.name == "some name"
      assert location.type == "some type"
      assert location.description == "some description"
      assert location.user_id == scope.user.id
    end

    test "create_location/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Locations.create_location(scope, @invalid_attrs)
    end

    test "update_location/3 with valid data updates the location" do
      scope = user_scope_fixture()
      location = location_fixture(scope)
      update_attrs = %{name: "some updated name", type: "some updated type", description: "some updated description"}

      assert {:ok, %Location{} = location} = Locations.update_location(scope, location, update_attrs)
      assert location.name == "some updated name"
      assert location.type == "some updated type"
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
      assert {:error, %Ecto.Changeset{}} = Locations.update_location(scope, location, @invalid_attrs)
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
end
