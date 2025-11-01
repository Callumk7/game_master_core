defmodule GameMasterCoreWeb.AuthorizationTestHelpers do
  @moduledoc """
  Shared helpers for authorization testing.
  """

  import ExUnit.Assertions
  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures
  alias GameMasterCore.Accounts.Scope

  @doc """
  Setup helper that creates test users with different roles for authorization testing.

  Returns a map with:
  - admin: User with admin role in test_game
  - game_master: User with game_master role in test_game
  - member_1: User with member role in test_game (creator of test entities)
  - member_2: User with member role in test_game (non-creator)
  - member_3: User with member role in test_game (for share testing)
  - non_member: User not in test_game at all
  - test_game: The game with all members added
  """
  def setup_test_users_and_game(_context) do
    # Create users
    admin_user = user_fixture(%{email: "admin@example.com"})
    game_master_user = user_fixture(%{email: "gm@example.com"})
    member_user_1 = user_fixture(%{email: "member1@example.com"})
    member_user_2 = user_fixture(%{email: "member2@example.com"})
    member_user_3 = user_fixture(%{email: "member3@example.com"})
    non_member_user = user_fixture(%{email: "nonmember@example.com"})

    # Create game as admin
    admin_scope = Scope.for_user(admin_user)
    test_game = game_fixture(admin_scope)

    # Add other users to the game
    game_scope = Scope.put_game(admin_scope, test_game)

    {:ok, _} = GameMasterCore.Games.add_member(game_scope, test_game, game_master_user.id, "game_master")
    {:ok, _} = GameMasterCore.Games.add_member(game_scope, test_game, member_user_1.id, "member")
    {:ok, _} = GameMasterCore.Games.add_member(game_scope, test_game, member_user_2.id, "member")
    {:ok, _} = GameMasterCore.Games.add_member(game_scope, test_game, member_user_3.id, "member")

    %{
      admin: admin_user,
      game_master: game_master_user,
      member_1: member_user_1,
      member_2: member_user_2,
      member_3: member_user_3,
      non_member: non_member_user,
      test_game: test_game
    }
  end

  @doc """
  Creates a scope for the given user with the test game.
  """
  def user_scope_for_game(user, game) do
    user
    |> Scope.for_user()
    |> Scope.put_game(game)
  end

  @doc """
  Helper to create entities with specific visibility/owner for testing.
  """
  def create_entity_for_user(entity_type, user, game, visibility \\ "private", attrs \\ %{}) do
    scope = user_scope_for_game(user, game)

    base_attrs = %{
      "name" => "Test #{entity_type}",
      "content" => "Test content for #{entity_type}",
      "visibility" => visibility,
      "game_id" => game.id
    }

    # Add entity-specific required fields
    base_attrs =
      case entity_type do
        :character ->
          Map.merge(base_attrs, %{"class" => "Fighter", "level" => 1})
        :faction ->
          base_attrs
        :location ->
          Map.merge(base_attrs, %{"type" => "town"})
        :quest ->
          base_attrs
        :note ->
          base_attrs
      end

    attrs = Map.merge(base_attrs, attrs)

    case entity_type do
      :character ->
        {:ok, character} = GameMasterCore.Characters.create_character(scope, attrs)
        character
      :faction ->
        {:ok, faction} = GameMasterCore.Factions.create_faction(scope, attrs)
        faction
      :location ->
        {:ok, location} = GameMasterCore.Locations.create_location(scope, attrs)
        location
      :quest ->
        {:ok, quest} = GameMasterCore.Quests.create_quest(scope, attrs)
        quest
      :note ->
        {:ok, note} = GameMasterCore.Notes.create_note(scope, attrs)
        note
    end
  end

  @doc """
  Helper to create shares for entities.
  """
  def share_entity_with_user(entity_type, entity, from_user, to_user, permission) do
    game = get_game_from_entity(entity)
    scope = user_scope_for_game(from_user, game)

    case entity_type do
      :character ->
        GameMasterCore.Characters.share_character(scope, entity, to_user.id, permission)
      :faction ->
        GameMasterCore.Factions.share_faction(scope, entity, to_user.id, permission)
      :location ->
        GameMasterCore.Locations.share_location(scope, entity, to_user.id, permission)
      :quest ->
        GameMasterCore.Quests.share_quest(scope, entity, to_user.id, permission)
      :note ->
        GameMasterCore.Notes.share_note(scope, entity, to_user.id, permission)
    end
  end

  @doc """
  Helper to get game from entity (assumes entity has game_id field).
  """
  def get_game_from_entity(entity) do
    GameMasterCore.Repo.get!(GameMasterCore.Games.Game, entity.game_id)
  end

  @doc """
  Asserts successful response with optional status code.
  """
  def assert_success_response(conn, expected_status \\ 200) do
    assert conn.status == expected_status
    assert conn.resp_body != nil
  end

  @doc """
  Asserts unauthorized/forbidden response.
  """
  def assert_unauthorized_response(conn, expected_status \\ 403) do
    assert conn.status == expected_status
  end

  @doc """
  Asserts not found response.
  """
  def assert_not_found_response(conn) do
    assert conn.status == 404
  end

  @doc """
  Asserts permission metadata in entity data.
  """
  def assert_has_permissions(entity_data, can_edit, can_delete, can_share) do
    assert entity_data["can_edit"] == can_edit
    assert entity_data["can_delete"] == can_delete
    assert entity_data["can_share"] == can_share
  end

  @doc """
  Makes an authenticated API request for the given user.
  """
  def authenticated_conn(user) do
    conn = Phoenix.ConnTest.build_conn()
    GameMasterCoreWeb.ConnCase.authenticate_api_user(conn, user)
  end
end
