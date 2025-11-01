defmodule GameMasterCoreWeb.AuthorizationTestHelpers do
  @moduledoc """
  Shared helpers for authorization testing in Phase 4.
  """

  import ExUnit.Assertions
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures

  alias GameMasterCore.Repo
  alias GameMasterCore.Accounts.Scope
  alias GameMasterCore.Games.GameMembership

  @doc """
  Sets up a complete test game with all required user roles.

  Returns a map with:
  - `:game` - The test game
  - `:admin` - Admin user
  - `:game_master` - Game master user
  - `:member_1` - First member user
  - `:member_2` - Second member user
  - `:member_3` - Third member user
  - `:non_member` - User not in the game
  """
  def setup_test_game_and_users(_context \\ %{}) do
    # Create users
    admin = user_fixture(%{email: "admin@test.com", username: "admin"})
    game_master = user_fixture(%{email: "gm@test.com", username: "gamemaster"})
    member_1 = user_fixture(%{email: "member1@test.com", username: "member1"})
    member_2 = user_fixture(%{email: "member2@test.com", username: "member2"})
    member_3 = user_fixture(%{email: "member3@test.com", username: "member3"})
    non_member = user_fixture(%{email: "nonmember@test.com", username: "nonmember"})

    # Create game with admin as owner
    admin_scope = Scope.for_user(admin)
    game = game_fixture(admin_scope, %{name: "Test Game"})

    # Add members with appropriate roles
    add_game_member(game, game_master, "game_master")
    add_game_member(game, member_1, "member")
    add_game_member(game, member_2, "member")
    add_game_member(game, member_3, "member")

    %{
      game: game,
      admin: admin,
      game_master: game_master,
      member_1: member_1,
      member_2: member_2,
      member_3: member_3,
      non_member: non_member
    }
  end

  @doc """
  Adds a member to a game with the specified role.
  """
  def add_game_member(game, user, role \\ "member") do
    attrs = %{
      game_id: game.id,
      user_id: user.id,
      role: role
    }

    %GameMembership{}
    |> GameMembership.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates an entity for a specific user with optional visibility.

  ## Options
  - `:visibility` - "private", "viewable", or "editable" (default: "private")
  - Additional entity-specific attributes
  """
  def create_entity_for_user(entity_type, user, game, attrs \\ %{}) do
    scope = Scope.for_user(user) |> Scope.put_game(game)

    default_attrs = %{
      visibility: Map.get(attrs, :visibility, "private"),
      game_id: game.id
    }

    attrs = Map.merge(default_attrs, attrs)

    case entity_type do
      :character -> GameMasterCore.CharactersFixtures.character_fixture(scope, attrs)
      :faction -> GameMasterCore.FactionsFixtures.faction_fixture(scope, attrs)
      :location -> GameMasterCore.LocationsFixtures.location_fixture(scope, attrs)
      :quest -> GameMasterCore.QuestsFixtures.quest_fixture(scope, attrs)
      :note -> GameMasterCore.NotesFixtures.note_fixture(scope, attrs)
    end
  end

  @doc """
  Shares an entity with a user using the specified permission.
  """
  def share_entity_with_user(_entity_type, entity, from_user, to_user, game, permission) do
    scope = Scope.for_user(from_user) |> Scope.put_game(game)

    {:ok, _share} = GameMasterCore.Authorization.share_entity(
      scope,
      entity,
      to_user.id,
      permission
    )
  end

  @doc """
  Asserts a successful response with the expected status code.
  """
  def assert_success_response(conn, expected_status \\ 200) do
    assert conn.status == expected_status
    conn
  end

  @doc """
  Asserts an unauthorized response (403 Forbidden).
  """
  def assert_unauthorized_response(conn, expected_status \\ 403) do
    assert conn.status == expected_status
    conn
  end

  @doc """
  Asserts a not found response (404).
  """
  def assert_not_found_response(conn) do
    assert conn.status == 404
    conn
  end

  @doc """
  Asserts a bad request response (400).
  """
  def assert_bad_request_response(conn) do
    assert conn.status == 400
    conn
  end

  @doc """
  Asserts that entity data includes the expected permission metadata.
  """
  def assert_has_permissions(entity_data, can_edit, can_delete, can_share) do
    assert entity_data["can_edit"] == can_edit,
      "Expected can_edit to be #{can_edit}, got #{entity_data["can_edit"]}"
    assert entity_data["can_delete"] == can_delete,
      "Expected can_delete to be #{can_delete}, got #{entity_data["can_delete"]}"
    assert entity_data["can_share"] == can_share,
      "Expected can_share to be #{can_share}, got #{entity_data["can_share"]}"
  end

  @doc """
  Gets the API path for an entity.
  """
  def entity_path(entity_type, game_id, entity_id \\ nil) do
    base = "/api/games/#{game_id}/#{entity_type}s"
    if entity_id, do: "#{base}/#{entity_id}", else: base
  end

  @doc """
  Gets the share API path for an entity.
  """
  def share_path(entity_type, game_id, entity_id, user_id \\ nil) do
    base = entity_path(entity_type, game_id, entity_id) <> "/share"
    if user_id, do: "#{base}/#{user_id}", else: base
  end

  @doc """
  Gets the visibility API path for an entity.
  """
  def visibility_path(entity_type, game_id, entity_id) do
    entity_path(entity_type, game_id, entity_id) <> "/visibility"
  end

  @doc """
  Gets the shares list API path for an entity.
  """
  def shares_list_path(entity_type, game_id, entity_id) do
    entity_path(entity_type, game_id, entity_id) <> "/shares"
  end
end
