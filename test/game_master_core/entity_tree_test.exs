defmodule GameMasterCore.EntityTreeTest do
  use GameMasterCore.DataCase, async: true

  alias GameMasterCore.EntityTree
  alias GameMasterCore.{Characters, Factions, Locations, Links}

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures

  describe "build_entity_tree/2" do
    setup do
      user = user_fixture()
      user_scope = GameMasterCore.Accounts.Scope.for_user(user)
      game = game_fixture(user_scope)
      scope = GameMasterCore.Accounts.Scope.put_game(user_scope, game)

      %{user: user, game: game, scope: scope}
    end

    test "returns empty tree for game with no entities", %{scope: scope} do
      tree = EntityTree.build_entity_tree(scope)

      assert %{
               characters: [],
               factions: [],
               locations: [],
               quests: [],
               notes: []
             } = tree
    end

    test "builds tree with single character", %{scope: scope} do
      {:ok, character} =
        Characters.create_character_for_game(scope, %{
          name: "Test Character",
          class: "Warrior",
          level: 1,
          content: "A test character"
        })

      tree = EntityTree.build_entity_tree(scope)

      assert %{characters: [char_node]} = tree
      assert char_node.id == character.id
      assert char_node.name == "Test Character"
      assert char_node.type == "character"
      assert char_node.children == []
    end

    test "builds tree with linked entities", %{scope: scope} do
      # Create entities
      {:ok, character} =
        Characters.create_character_for_game(scope, %{
          name: "Test Character",
          class: "Warrior",
          level: 1,
          content: "A test character"
        })

      {:ok, faction} =
        Factions.create_faction_for_game(scope, %{
          name: "Test Faction",
          content: "A test faction"
        })

      # Create link between character and faction
      {:ok, _link} =
        Links.link(character, faction, %{
          relationship_type: "member",
          description: "Character is a member",
          strength: 8
        })

      tree = EntityTree.build_entity_tree(scope)

      # Find the character in the tree
      char_node = Enum.find(tree.characters, &(&1.id == character.id))
      assert char_node != nil

      # Check that faction is linked as a child
      faction_child = Enum.find(char_node.children, &(&1.id == faction.id))
      assert faction_child != nil
      assert faction_child.relationship_type == "member"
      assert faction_child.description == "Character is a member"
      assert faction_child.strength == 8
    end

    test "respects depth limit", %{scope: scope} do
      # Create a chain: character -> faction -> location
      {:ok, character} =
        Characters.create_character_for_game(scope, %{
          name: "Character",
          class: "Warrior",
          level: 1,
          content: "Test"
        })

      {:ok, faction} =
        Factions.create_faction_for_game(scope, %{
          name: "Faction",
          content: "Test"
        })

      {:ok, location} =
        Locations.create_location_for_game(scope, %{
          name: "Location",
          type: "city",
          content: "Test"
        })

      {:ok, _} = Links.link(character, faction)
      {:ok, _} = Links.link(faction, location)

      # Build tree with depth 1 - should show character with faction (depth 0->1)
      tree = EntityTree.build_entity_tree(scope, depth: 1)
      char_node = Enum.find(tree.characters, &(&1.id == character.id))
      assert length(char_node.children) == 1
      faction_child = hd(char_node.children)
      assert faction_child.id == faction.id
      # Faction should have no children at depth 1
      assert faction_child.children == []

      # Build tree with depth 2 - should show character -> faction -> location
      tree = EntityTree.build_entity_tree(scope, depth: 2)
      char_node = Enum.find(tree.characters, &(&1.id == character.id))
      assert length(char_node.children) == 1
      faction_child = hd(char_node.children)
      assert faction_child.id == faction.id
      assert length(faction_child.children) == 1
      location_child = hd(faction_child.children)
      assert location_child.id == location.id
      assert location_child.children == []
    end

    test "builds tree from specific starting entity", %{scope: scope} do
      {:ok, character} =
        Characters.create_character_for_game(scope, %{
          name: "Character",
          class: "Warrior",
          level: 1,
          content: "Test"
        })

      {:ok, faction} =
        Factions.create_faction_for_game(scope, %{
          name: "Faction",
          content: "Test"
        })

      {:ok, _} = Links.link(character, faction)

      {:ok, tree} = EntityTree.build_tree_from_entity(scope, "character", character.id, 3)

      assert tree.id == character.id
      assert tree.name == "Character"
      assert tree.type == "character"
      assert length(tree.children) == 1

      faction_child = hd(tree.children)
      assert faction_child.id == faction.id
      assert faction_child.name == "Faction"
      assert faction_child.type == "faction"
    end

    test "handles non-existent starting entity", %{scope: scope} do
      fake_id = Ecto.UUID.generate()
      result = EntityTree.build_tree_from_entity(scope, "character", fake_id, 3)
      assert {:error, :not_found} = result
    end

    test "handles invalid entity type", %{scope: scope} do
      fake_id = Ecto.UUID.generate()
      result = EntityTree.build_tree_from_entity(scope, "invalid_type", fake_id, 3)
      assert {:error, :invalid_entity_type} = result
    end
  end
end
