defmodule GameMasterCore.SearchTest do
  use GameMasterCore.DataCase

  alias GameMasterCore.Search

  import GameMasterCore.AccountsFixtures
  import GameMasterCore.GamesFixtures
  import GameMasterCore.CharactersFixtures
  import GameMasterCore.FactionsFixtures
  import GameMasterCore.LocationsFixtures
  import GameMasterCore.QuestsFixtures
  import GameMasterCore.NotesFixtures

  describe "search_game/3" do
    setup do
      scope = game_scope_fixture()
      {:ok, scope: scope}
    end

    test "searches by name across all entity types", %{scope: scope} do
      # Create entities with "dragon" in the name
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "A brave hero",
        game_id: scope.game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "A secretive order",
        game_id: scope.game.id
      })

      location_fixture(scope, %{
        name: "Dragon's Lair",
        type: "complex",
        content_plain_text: "A dangerous cave",
        game_id: scope.game.id
      })

      quest_fixture(scope, %{
        name: "Defeat the Dragon",
        content_plain_text: "An epic quest",
        game_id: scope.game.id
      })

      note_fixture(scope, %{
        name: "Dragon Lore",
        content_plain_text: "Ancient knowledge",
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "dragon")

      assert results.query == "dragon"
      assert results.total_results == 5
      assert length(results.results.characters) == 1
      assert length(results.results.factions) == 1
      assert length(results.results.locations) == 1
      assert length(results.results.quests) == 1
      assert length(results.results.notes) == 1
    end

    test "searches by content_plain_text", %{scope: scope} do
      # Create entities with "ancient" only in content
      character_fixture(scope, %{
        name: "Hero",
        content_plain_text: "ancient warrior",
        game_id: scope.game.id
      })

      faction_fixture(scope, %{
        name: "Guild",
        content_plain_text: "ancient order",
        game_id: scope.game.id
      })

      location_fixture(scope, %{
        name: "Temple",
        type: "building",
        content_plain_text: "ancient ruins",
        game_id: scope.game.id
      })

      quest_fixture(scope, %{
        name: "Quest",
        content_plain_text: "ancient artifact",
        game_id: scope.game.id
      })

      note_fixture(scope, %{
        name: "Note",
        content_plain_text: "ancient knowledge",
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "ancient")

      assert results.total_results == 5
      assert length(results.results.characters) == 1
      assert length(results.results.factions) == 1
      assert length(results.results.locations) == 1
      assert length(results.results.quests) == 1
      assert length(results.results.notes) == 1
    end

    test "is case-insensitive", %{scope: scope} do
      character_fixture(scope, %{
        name: "DRAGON KING",
        content_plain_text: "ruler",
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "dragon knight",
        content_plain_text: "warrior",
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "DrAgOn Hunter",
        content_plain_text: "tracker",
        game_id: scope.game.id
      })

      # Search with different cases
      results_lower = Search.search_game(scope, "dragon")
      results_upper = Search.search_game(scope, "DRAGON")
      results_mixed = Search.search_game(scope, "DrAgOn")

      assert results_lower.total_results == 3
      assert results_upper.total_results == 3
      assert results_mixed.total_results == 3
    end

    test "filters by entity_types", %{scope: scope} do
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "hero",
        game_id: scope.game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "order",
        game_id: scope.game.id
      })

      location_fixture(scope, %{
        name: "Dragon's Lair",
        type: "complex",
        content_plain_text: "cave",
        game_id: scope.game.id
      })

      # Search only characters and factions
      results = Search.search_game(scope, "dragon", entity_types: ["character", "faction"])

      assert results.total_results == 2
      assert length(results.results.characters) == 1
      assert length(results.results.factions) == 1
      assert length(results.results.locations) == 0
      assert length(results.results.quests) == 0
      assert length(results.results.notes) == 0
    end

    test "filters by tags with AND logic", %{scope: scope} do
      # Create characters with different tag combinations
      character_fixture(scope, %{
        name: "Villain",
        content_plain_text: "evil character",
        tags: ["npc", "villain"],
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Hero",
        content_plain_text: "good character",
        tags: ["npc", "hero"],
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Boss",
        content_plain_text: "powerful character",
        tags: ["villain", "boss"],
        game_id: scope.game.id
      })

      # Search for entities with both "npc" AND "villain"
      results = Search.search_game(scope, "ill", tags: ["npc", "villain"])

      assert results.total_results == 1
      assert hd(results.results.characters).name == "Villain"
    end

    test "filters by pinned_only", %{scope: scope} do
      character_fixture(scope, %{
        name: "Dragon King",
        content_plain_text: "ruler",
        pinned: true,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon Knight",
        content_plain_text: "warrior",
        pinned: false,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon Hunter",
        content_plain_text: "tracker",
        pinned: false,
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "dragon", pinned_only: true)

      assert results.total_results == 1
      assert results.filters.pinned_only == true
      assert hd(results.results.characters).name == "Dragon King"
    end

    test "respects limit parameter", %{scope: scope} do
      # Create 5 characters
      for i <- 1..5 do
        character_fixture(scope, %{
          name: "Dragon #{i}",
          content_plain_text: "character #{i}",
          game_id: scope.game.id
        })
      end

      results = Search.search_game(scope, "dragon", limit: 2)

      assert results.pagination.limit == 2
      assert length(results.results.characters) == 2
    end

    test "respects offset parameter", %{scope: scope} do
      # Create characters with predictable names for sorting
      character_fixture(scope, %{
        name: "Dragon A",
        content_plain_text: "first",
        pinned: false,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon B",
        content_plain_text: "second",
        pinned: false,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon C",
        content_plain_text: "third",
        pinned: false,
        game_id: scope.game.id
      })

      results_page_1 = Search.search_game(scope, "dragon", limit: 2, offset: 0)
      results_page_2 = Search.search_game(scope, "dragon", limit: 2, offset: 2)

      assert results_page_1.pagination.offset == 0
      assert length(results_page_1.results.characters) == 2

      assert results_page_2.pagination.offset == 2
      assert length(results_page_2.results.characters) == 1
    end

    test "enforces max limit of 100", %{scope: scope} do
      character_fixture(scope, %{
        name: "Dragon",
        content_plain_text: "test",
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "dragon", limit: 200)

      assert results.pagination.limit == 100
    end

    test "uses default limit of 50 when not specified", %{scope: scope} do
      character_fixture(scope, %{
        name: "Dragon",
        content_plain_text: "test",
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "dragon")

      assert results.pagination.limit == 50
    end

    test "orders results by pinned status then name", %{scope: scope} do
      # Create characters in random order with mixed pinned status
      character_fixture(scope, %{
        name: "Dragon C",
        content_plain_text: "third",
        pinned: false,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon A",
        content_plain_text: "first",
        pinned: true,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon B",
        content_plain_text: "second",
        pinned: true,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon D",
        content_plain_text: "fourth",
        pinned: false,
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "dragon")

      names = Enum.map(results.results.characters, & &1.name)
      # Pinned first (A, B), then unpinned sorted by name (C, D)
      assert names == ["Dragon A", "Dragon B", "Dragon C", "Dragon D"]
    end

    test "only searches within the game scope", %{scope: scope} do
      other_scope = game_scope_fixture()
      other_game = game_fixture(other_scope)

      # Create entity in current game
      character_fixture(scope, %{
        name: "Dragon Slayer",
        content_plain_text: "hero",
        game_id: scope.game.id
      })

      # Create entity in other game
      character_fixture(other_scope, %{
        name: "Dragon Knight",
        content_plain_text: "warrior",
        game_id: other_game.id
      })

      results = Search.search_game(scope, "dragon")

      assert results.total_results == 1
      assert hd(results.results.characters).name == "Dragon Slayer"
    end

    test "returns empty results when no matches found", %{scope: scope} do
      results = Search.search_game(scope, "nonexistent")

      assert results.total_results == 0
      assert results.results.characters == []
      assert results.results.factions == []
      assert results.results.locations == []
      assert results.results.quests == []
      assert results.results.notes == []
    end

    test "handles special characters in search query", %{scope: scope} do
      character_fixture(scope, %{
        name: "Dragon's Lair",
        content_plain_text: "location",
        game_id: scope.game.id
      })

      results = Search.search_game(scope, "Dragon's")

      assert results.total_results == 1
    end

    test "combines multiple filters", %{scope: scope} do
      # Create various characters
      character_fixture(scope, %{
        name: "Dragon King",
        content_plain_text: "ruler",
        tags: ["boss", "villain"],
        pinned: true,
        game_id: scope.game.id
      })

      character_fixture(scope, %{
        name: "Dragon Knight",
        content_plain_text: "warrior",
        tags: ["boss", "villain"],
        pinned: false,
        game_id: scope.game.id
      })

      faction_fixture(scope, %{
        name: "Dragon Cult",
        content_plain_text: "order",
        tags: ["boss", "villain"],
        pinned: true,
        game_id: scope.game.id
      })

      # Search with entity_types, tags, and pinned_only
      results =
        Search.search_game(scope, "dragon",
          entity_types: ["character"],
          tags: ["boss", "villain"],
          pinned_only: true
        )

      assert results.total_results == 1
      assert hd(results.results.characters).name == "Dragon King"
      assert results.results.factions == []
    end
  end
end
