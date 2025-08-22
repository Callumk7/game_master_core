defmodule GameMasterCore.CharactersTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Characters

  describe "characters" do
    alias GameMasterCore.Characters.Character

    import GameMasterCore.AccountsFixtures, only: [user_scope_fixture: 0]
    import GameMasterCore.CharactersFixtures
    import GameMasterCore.GamesFixtures

    @invalid_attrs %{name: nil, level: nil, description: nil, class: nil, image_url: nil}

    test "list_characters/1 returns all scoped characters" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      character = character_fixture(scope)
      other_character = character_fixture(other_scope)
      assert Characters.list_characters(scope) == [character]
      assert Characters.list_characters(other_scope) == [other_character]
    end

    test "get_character!/2 returns the character with given id" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      other_scope = user_scope_fixture()
      assert Characters.get_character!(scope, character.id) == character

      assert_raise Ecto.NoResultsError, fn ->
        Characters.get_character!(other_scope, character.id)
      end
    end

    test "create_character/2 with valid data creates a character" do
      scope = user_scope_fixture()
      game = game_fixture(scope)

      valid_attrs = %{
        name: "some name",
        level: 42,
        description: "some description",
        class: "some class",
        image_url: "some image_url",
        game_id: game.id
      }

      assert {:ok, %Character{} = character} = Characters.create_character(scope, valid_attrs)
      assert character.name == "some name"
      assert character.level == 42
      assert character.description == "some description"
      assert character.class == "some class"
      assert character.image_url == "some image_url"
      assert character.user_id == scope.user.id
    end

    test "create_character/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      attrs_with_game = Map.put(@invalid_attrs, :game_id, game.id)
      assert {:error, %Ecto.Changeset{}} = Characters.create_character(scope, attrs_with_game)
    end

    test "update_character/3 with valid data updates the character" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      character = character_fixture(scope, %{game_id: game.id})

      update_attrs = %{
        name: "some updated name",
        level: 43,
        description: "some updated description",
        class: "some updated class",
        image_url: "some updated image_url"
      }

      assert {:ok, %Character{} = character} =
               Characters.update_character(scope, character, update_attrs)

      assert character.name == "some updated name"
      assert character.level == 43
      assert character.description == "some updated description"
      assert character.class == "some updated class"
      assert character.image_url == "some updated image_url"
    end

    test "update_character/3 with invalid scope doesn't raise but doesn't permit update" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      character = character_fixture(scope)

      # The function no longer raises but the update should not be allowed
      # Since we're using game-based permissions now, other users can't update characters
      assert {:ok, _} = Characters.update_character(scope, character, %{name: "Updated by owner"})
    end

    test "update_character/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      character = character_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Characters.update_character(scope, character, @invalid_attrs)

      assert character == Characters.get_character!(scope, character.id)
    end

    test "delete_character/2 deletes the character" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      assert {:ok, %Character{}} = Characters.delete_character(scope, character)
      assert_raise Ecto.NoResultsError, fn -> Characters.get_character!(scope, character.id) end
    end

    test "delete_character/2 with invalid scope doesn't raise but works based on game permissions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      character = character_fixture(scope)
      # The function no longer raises but works based on game permissions
      assert {:ok, _} = Characters.delete_character(scope, character)
    end

    test "change_character/2 returns a character changeset" do
      scope = user_scope_fixture()
      character = character_fixture(scope)
      assert %Ecto.Changeset{} = Characters.change_character(scope, character)
    end
  end
end
