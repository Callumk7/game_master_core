defmodule GameMasterCoreWeb.SwaggerDefinitions do
  @moduledoc """
  Centralized Swagger schema definitions to reduce boilerplate across controllers.
  """

  import PhoenixSwagger
  alias PhoenixSwagger.Schema

  def game_schema do
    swagger_schema do
      title("Game")
      description("A game instance")

      properties do
        id(:string, "Game ID", required: true, format: :uuid)
        name(:string, "Game name", required: true)
        description(:string, "Game description")
        setting(:string, "Game setting")
        owner_id(:integer, "Owner user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "123e4567-e89b-12d3-a456-426614174000",
        name: "My Campaign",
        description: "An epic adventure",
        setting: "Fantasy",
        owner_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def game_create_params_schema do
    swagger_schema do
      title("Game Create Parameters")
      description("Parameters for creating a new game")

      properties do
        name(:string, "Game name", required: true)
        description(:string, "Game description")
        setting(:string, "Game setting")
      end

      required([:name])

      example(%{
        name: "My Campaign",
        description: "An epic adventure",
        setting: "Fantasy"
      })
    end
  end

  def game_update_params_schema do
    swagger_schema do
      title("Game Update Parameters")
      description("Parameters for updating an existing game (partial updates supported)")

      properties do
        name(:string, "Game name")
        description(:string, "Game description")
        setting(:string, "Game setting")
      end

      example(%{
        name: "My Updated Campaign"
      })
    end
  end

  def game_create_request_schema do
    swagger_schema do
      title("Game Create Request")
      description("Game creation parameters")

      properties do
        game(Schema.ref(:GameCreateParams), "Game parameters")
      end

      required([:game])
    end
  end

  def game_update_request_schema do
    swagger_schema do
      title("Game Update Request")
      description("Game update parameters")

      properties do
        game(Schema.ref(:GameUpdateParams), "Game parameters")
      end

      required([:game])
    end
  end

  def member_schema do
    swagger_schema do
      title("Member")
      description("A game member")

      properties do
        user_id(:integer, "User ID", required: true)
        email(:string, "User email", required: true)
        role(:string, "Member role", required: true)
        joined_at(:string, "Join timestamp", format: :datetime)
      end

      example(%{
        user_id: 1,
        email: "user@example.com",
        role: "member",
        joined_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entity_note_schema do
    swagger_schema do
      title("Entity Note")
      description("Note entity in game entities list")

      properties do
        id(:string, "Note ID", required: true, format: :uuid)
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
        tags(Schema.array(:string), "Tags associated with this note")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "223e4567-e89b-12d3-a456-426614174001",
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        tags: ["important", "dragon", "quest"],
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entity_character_schema do
    swagger_schema do
      title("Entity Character")
      description("Character entity in game entities list")

      properties do
        id(:string, "Character ID", required: true, format: :uuid)
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
        tags(Schema.array(:string), "Tags associated with this character")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "323e4567-e89b-12d3-a456-426614174002",
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg",
        tags: ["npc", "ally", "wizard"],
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entity_faction_schema do
    swagger_schema do
      title("Entity Faction")
      description("Faction entity in game entities list")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
        tags(Schema.array(:string), "Tags associated with this faction")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "423e4567-e89b-12d3-a456-426614174003",
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        tags: ["secret", "political", "antagonist"],
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entity_location_schema do
    swagger_schema do
      title("Entity Location")
      description("Location entity in game entities list")

      properties do
        id(:string, "Location ID", required: true, format: :uuid)
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        has_parent(:boolean, "Whether this location has a parent location", required: true)
        tags(Schema.array(:string), "Tags associated with this location")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "523e4567-e89b-12d3-a456-426614174004",
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        has_parent: true,
        tags: ["magical", "hidden", "dangerous"],
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entity_quest_schema do
    swagger_schema do
      title("Entity Quest")
      description("Quest entity in game entities list")

      properties do
        id(:string, "Quest ID", required: true, format: :uuid)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
        tags(Schema.array(:string), "Tags associated with this quest")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "623e4567-e89b-12d3-a456-426614174005",
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure", "exploration"],
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def entities_schema do
    swagger_schema do
      title("Entities")
      description("Collection of game entities")

      properties do
        notes(Schema.array(:EntityNote), "Notes list")
        characters(Schema.array(:EntityCharacter), "Characters list")
        factions(Schema.array(:EntityFaction), "Factions list")
        locations(Schema.array(:EntityLocation), "Locations list")
        quests(Schema.array(:EntityQuest), "Quests list")
      end
    end
  end

  def entities_data_schema do
    swagger_schema do
      title("Entities Data")
      description("Game entities data structure")

      properties do
        game_id(:string, "Game ID", required: true, format: :uuid)
        game_name(:string, "Game name", required: true)
        entities(Schema.ref(:Entities), "Game entities")
      end
    end
  end

  # Response wrappers
  def response_schema(data_ref, title, description, example \\ nil) do
    schema =
      swagger_schema do
        title(title)
        description(description)

        properties do
          data(data_ref, "Response data")
        end
      end

    if example, do: Map.put(schema, :example, example), else: schema
  end

  def array_response_schema(item_ref, title, description, example \\ nil) do
    schema =
      swagger_schema do
        title(title)
        description(description)

        properties do
          data(Schema.array(item_ref), "Response data")
        end
      end

    if example, do: Map.put(schema, :example, example), else: schema
  end

  # Error schemas
  def error_schema do
    swagger_schema do
      title("Error")
      description("Error response")

      properties do
        errors(Schema.ref(:ErrorDetails), "Error details")
      end
    end
  end

  def error_details_schema do
    swagger_schema do
      title("Error Details")
      description("Detailed error information")
      type(:object)
    end
  end

  def note_schema do
    swagger_schema do
      title("Note")
      description("A game note")

      properties do
        id(:string, "Note ID", required: true, format: :uuid)
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
        tags(Schema.array(:string), "Tags associated with this note")
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:integer, "Author user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "223e4567-e89b-12d3-a456-426614174001",
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        tags: ["important", "dragon", "quest"],
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def note_create_params_schema do
    swagger_schema do
      title("Note Create Parameters")
      description("Parameters for creating a new note")

      properties do
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
        tags(Schema.array(:string), "Tags for this note")
      end

      required([:name, :content])

      example(%{
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        tags: ["important", "dragon"]
      })
    end
  end

  def note_update_params_schema do
    swagger_schema do
      title("Note Update Parameters")
      description("Parameters for updating an existing note (partial updates supported)")

      properties do
        name(:string, "Note name")
        content(:string, "Note content")
        tags(Schema.array(:string), "Tags for this note")
      end

      example(%{
        name: "Updated Quest Notes"
      })
    end
  end

  def note_create_request_schema do
    swagger_schema do
      title("Note Create Request")
      description("Note creation parameters")

      properties do
        note(Schema.ref(:NoteCreateParams), "Note parameters")
      end

      required([:note])
    end
  end

  def note_update_request_schema do
    swagger_schema do
      title("Note Update Request")
      description("Note update parameters")

      properties do
        note(Schema.ref(:NoteUpdateParams), "Note parameters")
      end

      required([:note])
    end
  end

  def note_links_data_schema do
    swagger_schema do
      title("Note Links Data")
      description("Links associated with a note")

      properties do
        note_id(:string, "Note ID", required: true, format: :uuid)
        note_name(:string, "Note name", required: true)
        links(Schema.ref(:NoteLinks), "Associated entity links")
      end
    end
  end

  def note_links_schema do
    swagger_schema do
      title("Note Links")
      description("Collections of entities linked to a note")

      properties do
        characters(Schema.array(:EntityCharacter), "Linked characters")
        factions(Schema.array(:EntityFaction), "Linked factions")
        locations(Schema.array(:EntityLocation), "Linked locations")
        quests(Schema.array(:EntityQuest), "Linked quests")
        notes(Schema.array(:EntityNote), "Linked notes")
      end
    end
  end

  def character_schema do
    swagger_schema do
      title("Character")
      description("A game character")

      properties do
        id(:string, "Character ID", required: true, format: :uuid)
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
        tags(Schema.array(:string), "Tags associated with this character")
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "323e4567-e89b-12d3-a456-426614174002",
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg",
        tags: ["npc", "ally", "wizard"],
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def character_create_params_schema do
    swagger_schema do
      title("Character Create Parameters")
      description("Parameters for creating a new character")

      properties do
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
        tags(Schema.array(:string), "Tags for this character")
      end

      required([:name, :class, :level])

      example(%{
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg",
        tags: ["npc", "ally", "wizard"]
      })
    end
  end

  def character_update_params_schema do
    swagger_schema do
      title("Character Update Parameters")
      description("Parameters for updating an existing character (partial updates supported)")

      properties do
        name(:string, "Character name")
        description(:string, "Character description")
        class(:string, "Character class")
        level(:integer, "Character level")
        image_url(:string, "Character image URL")
        tags(Schema.array(:string), "Tags for this character")
      end

      example(%{
        level: 21,
        description: "A wise and powerful wizard who guides the Fellowship through many perils."
      })
    end
  end

  def character_create_request_schema do
    swagger_schema do
      title("Character Create Request")
      description("Character creation parameters")

      properties do
        character(Schema.ref(:CharacterCreateParams), "Character parameters")
      end

      required([:character])
    end
  end

  def character_update_request_schema do
    swagger_schema do
      title("Character Update Request")
      description("Character update parameters")

      properties do
        character(Schema.ref(:CharacterUpdateParams), "Character parameters")
      end

      required([:character])
    end
  end

  def character_links_data_schema do
    swagger_schema do
      title("Character Links Data")
      description("Links associated with a character")

      properties do
        character_id(:string, "Character ID", required: true, format: :uuid)
        character_name(:string, "Character name", required: true)
        links(Schema.ref(:CharacterLinks), "Associated entity links")
      end
    end
  end

  def character_links_schema do
    swagger_schema do
      title("Character Links")
      description("Collections of entities linked to a character")

      properties do
        notes(Schema.array(:EntityNote), "Linked notes")
        factions(Schema.array(:EntityFaction), "Linked factions")
        locations(Schema.array(:EntityLocation), "Linked locations")
        quests(Schema.array(:EntityQuest), "Linked quests")
        characters(Schema.array(:EntityCharacter), "Linked characters")
      end
    end
  end

  def faction_schema do
    swagger_schema do
      title("Faction")
      description("A game faction")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
        tags(Schema.array(:string), "Tags associated with this faction")
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "423e4567-e89b-12d3-a456-426614174003",
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        tags: ["secret", "political", "antagonist"],
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def faction_create_params_schema do
    swagger_schema do
      title("Faction Create Parameters")
      description("Parameters for creating a new faction")

      properties do
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
        tags(Schema.array(:string), "Tags for this faction")
      end

      required([:name, :description])

      example(%{
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        tags: ["secret", "political"]
      })
    end
  end

  def faction_update_params_schema do
    swagger_schema do
      title("Faction Update Parameters")
      description("Parameters for updating an existing faction (partial updates supported)")

      properties do
        name(:string, "Faction name")
        description(:string, "Faction description")
        tags(Schema.array(:string), "Tags for this faction")
      end

      example(%{
        description:
          "A secretive organization that seeks to control the entire realm from behind the scenes, now with expanded influence."
      })
    end
  end

  def faction_create_request_schema do
    swagger_schema do
      title("Faction Create Request")
      description("Faction creation parameters")

      properties do
        faction(Schema.ref(:FactionCreateParams), "Faction parameters")
      end

      required([:faction])
    end
  end

  def faction_update_request_schema do
    swagger_schema do
      title("Faction Update Request")
      description("Faction update parameters")

      properties do
        faction(Schema.ref(:FactionUpdateParams), "Faction parameters")
      end

      required([:faction])
    end
  end

  def faction_links_data_schema do
    swagger_schema do
      title("Faction Links Data")
      description("Links associated with a faction")

      properties do
        faction_id(:string, "Faction ID", required: true, format: :uuid)
        faction_name(:string, "Faction name", required: true)
        links(Schema.ref(:FactionLinks), "Associated entity links")
      end
    end
  end

  def faction_links_schema do
    swagger_schema do
      title("Faction Links")
      description("Collections of entities linked to a faction")

      properties do
        notes(Schema.array(:EntityNote), "Linked notes")
        characters(Schema.array(:EntityCharacter), "Linked characters")
        locations(Schema.array(:EntityLocation), "Linked locations")
        quests(Schema.array(:EntityQuest), "Linked quests")
        factions(Schema.array(:EntityFaction), "Linked factions")
      end
    end
  end

  def link_request_schema do
    swagger_schema do
      title("Link Request")
      description("Request to create a link between entities")

      properties do
        entity_type(:string, "Entity type to link",
          required: true,
          enum: [:character, :faction, :location, :quest]
        )

        entity_id(:string, "Entity ID to link", required: true, format: :uuid)
      end

      required([:entity_type, :entity_id])

      example(%{
        entity_type: "character",
        entity_id: "323e4567-e89b-12d3-a456-426614174002"
      })
    end
  end

  def location_schema do
    swagger_schema do
      title("Location")
      description("A game location")

      properties do
        id(:string, "Location ID", required: true, format: :uuid)
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:string, "Parent location ID", format: :uuid)
        tags(Schema.array(:string), "Tags associated with this location")
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "523e4567-e89b-12d3-a456-426614174004",
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        tags: ["magical", "hidden", "dangerous"],
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def location_create_params_schema do
    swagger_schema do
      title("Location Create Parameters")
      description("Parameters for creating a new location")

      properties do
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:string, "Parent location ID", format: :uuid)
        tags(Schema.array(:string), "Tags for this location")
      end

      required([:name, :type])

      example(%{
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        tags: ["magical", "hidden"]
      })
    end
  end

  def location_update_params_schema do
    swagger_schema do
      title("Location Update Parameters")
      description("Parameters for updating an existing location (partial updates supported)")

      properties do
        name(:string, "Location name")
        description(:string, "Location description")

        type(:string, "Location type",
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:string, "Parent location ID", format: :uuid)
        tags(Schema.array(:string), "Tags for this location")
      end

      example(%{
        description:
          "A mysterious cave hidden deep in the mountains, known for its brilliant glowing crystals and ancient runes."
      })
    end
  end

  def location_create_request_schema do
    swagger_schema do
      title("Location Create Request")
      description("Location creation parameters")

      properties do
        location(Schema.ref(:LocationCreateParams), "Location parameters")
      end

      required([:location])
    end
  end

  def location_update_request_schema do
    swagger_schema do
      title("Location Update Request")
      description("Location update parameters")

      properties do
        location(Schema.ref(:LocationUpdateParams), "Location parameters")
      end

      required([:location])
    end
  end

  def location_links_data_schema do
    swagger_schema do
      title("Location Links Data")
      description("Links associated with a location")

      properties do
        location_id(:string, "Location ID", required: true, format: :uuid)
        location_name(:string, "Location name", required: true)
        links(Schema.ref(:LocationLinks), "Associated entity links")
      end
    end
  end

  def location_links_schema do
    swagger_schema do
      title("Location Links")
      description("Collections of entities linked to a location")

      properties do
        notes(Schema.array(:EntityNote), "Linked notes")
        characters(Schema.array(:EntityCharacter), "Linked characters")
        factions(Schema.array(:EntityFaction), "Linked factions")
        quests(Schema.array(:EntityQuest), "Linked quests")
        locations(Schema.array(:EntityLocation), "Linked locations")
      end
    end
  end

  def quest_schema do
    swagger_schema do
      title("Quest")
      description("A game quest")

      properties do
        id(:string, "Quest ID", required: true, format: :uuid)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
        tags(Schema.array(:string), "Tags associated with this quest")
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "623e4567-e89b-12d3-a456-426614174005",
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure", "exploration"],
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def quest_create_params_schema do
    swagger_schema do
      title("Quest Create Parameters")
      description("Parameters for creating a new quest")

      properties do
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
        tags(Schema.array(:string), "Tags for this quest")
      end

      required([:name, :content])

      example(%{
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure"]
      })
    end
  end

  def quest_update_params_schema do
    swagger_schema do
      title("Quest Update Parameters")
      description("Parameters for updating an existing quest (partial updates supported)")

      properties do
        name(:string, "Quest name")
        content(:string, "Quest content")
        tags(Schema.array(:string), "Tags for this quest")
      end

      example(%{
        content:
          "Find the lost treasure hidden deep within the ancient ruins beneath the Crystal Cave. Beware of the guardian spirits."
      })
    end
  end

  def quest_create_request_schema do
    swagger_schema do
      title("Quest Create Request")
      description("Quest creation parameters")

      properties do
        quest(Schema.ref(:QuestCreateParams), "Quest parameters")
      end

      required([:quest])
    end
  end

  def quest_update_request_schema do
    swagger_schema do
      title("Quest Update Request")
      description("Quest update parameters")

      properties do
        quest(Schema.ref(:QuestUpdateParams), "Quest parameters")
      end

      required([:quest])
    end
  end

  def quest_links_data_schema do
    swagger_schema do
      title("Quest Links Data")
      description("Links associated with a quest")

      properties do
        quest_id(:string, "Quest ID", required: true, format: :uuid)
        quest_name(:string, "Quest name", required: true)
        links(Schema.ref(:QuestLinks), "Associated entity links")
      end
    end
  end

  def quest_links_schema do
    swagger_schema do
      title("Quest Links")
      description("Collections of entities linked to a quest")

      properties do
        notes(Schema.array(:EntityNote), "Linked notes")
        characters(Schema.array(:EntityCharacter), "Linked characters")
        factions(Schema.array(:EntityFaction), "Linked factions")
        locations(Schema.array(:EntityLocation), "Linked locations")
        quests(Schema.array(:EntityQuest), "Linked quests")
      end
    end
  end

  # Helper functions for response schemas
  def quest_response_schema do
    response_schema(Schema.ref(:Quest), "Quest Response", "Response containing a single quest")
  end

  def quests_response_schema do
    array_response_schema(:Quest, "Quests Response", "Response containing a list of quests")
  end

  def quest_links_response_schema do
    response_schema(
      Schema.ref(:QuestLinksData),
      "Quest Links Response",
      "Response containing quest links"
    )
  end

  # Authentication schemas

  def user_schema do
    swagger_schema do
      title("User")
      description("User information")

      properties do
        id(:integer, "User ID", required: true)
        email(:string, "User email", required: true)
        confirmed_at(:string, "Email confirmation timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        email: "user@example.com",
        confirmed_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def login_request_schema do
    swagger_schema do
      title("Login Request")
      description("Login credentials - either email/password or magic link token")

      properties do
        email(:string, "User email")
        password(:string, "User password")
        token(:string, "Magic link token")
      end

      example(%{
        email: "user@example.com",
        password: "password123"
      })
    end
  end

  def login_response_schema do
    swagger_schema do
      title("Login Response")
      description("Successful login response")

      properties do
        token(:string, "Session token (Base64 encoded)", required: true)
        user(Schema.ref(:User), "User information", required: true)
      end

      example(%{
        token: "dGVzdF90b2tlbg==",
        user: %{
          id: 1,
          email: "user@example.com",
          confirmed_at: "2023-08-20T12:00:00Z"
        }
      })
    end
  end

  def auth_status_response_schema do
    swagger_schema do
      title("Auth Status Response")
      description("Authentication status response")

      properties do
        authenticated(:boolean, "Whether user is authenticated", required: true)
        user(Schema.ref(:User), "User information if authenticated")
      end

      example(%{
        authenticated: true,
        user: %{
          id: 1,
          email: "user@example.com",
          confirmed_at: "2023-08-20T12:00:00Z"
        }
      })
    end
  end

  def signup_request_schema do
    swagger_schema do
      title("Signup Request")
      description("User registration credentials")

      properties do
        email(:string, "User email", required: true)
        password(:string, "User password", required: true)
      end

      required([:email, :password])

      example(%{
        email: "user@example.com",
        password: "password123"
      })
    end
  end

  # Common definitions map
  def common_definitions do
    %{
      Game: game_schema(),
      GameCreateParams: game_create_params_schema(),
      GameUpdateParams: game_update_params_schema(),
      GameCreateRequest: game_create_request_schema(),
      GameUpdateRequest: game_update_request_schema(),
      GameResponse:
        response_schema(Schema.ref(:Game), "Game Response", "Response containing a single game"),
      GamesResponse:
        array_response_schema(:Game, "Games Response", "Response containing a list of games"),
      Member: member_schema(),
      MembersResponse:
        array_response_schema(
          :Member,
          "Members Response",
          "Response containing a list of game members"
        ),
      EntityNote: entity_note_schema(),
      EntityCharacter: entity_character_schema(),
      EntityFaction: entity_faction_schema(),
      EntityLocation: entity_location_schema(),
      EntityQuest: entity_quest_schema(),
      Note: note_schema(),
      NoteCreateParams: note_create_params_schema(),
      NoteUpdateParams: note_update_params_schema(),
      NoteCreateRequest: note_create_request_schema(),
      NoteUpdateRequest: note_update_request_schema(),
      NoteResponse:
        response_schema(Schema.ref(:Note), "Note Response", "Response containing a single note"),
      NotesResponse:
        array_response_schema(:Note, "Notes Response", "Response containing a list of notes"),
      NoteLinksData: note_links_data_schema(),
      NoteLinks: note_links_schema(),
      NoteLinksResponse:
        response_schema(
          Schema.ref(:NoteLinksData),
          "Note Links Response",
          "Response containing note links"
        ),
      Character: character_schema(),
      CharacterCreateParams: character_create_params_schema(),
      CharacterUpdateParams: character_update_params_schema(),
      CharacterCreateRequest: character_create_request_schema(),
      CharacterUpdateRequest: character_update_request_schema(),
      CharacterResponse:
        response_schema(
          Schema.ref(:Character),
          "Character Response",
          "Response containing a single character"
        ),
      CharactersResponse:
        array_response_schema(
          :Character,
          "Characters Response",
          "Response containing a list of characters"
        ),
      CharacterLinksData: character_links_data_schema(),
      CharacterLinks: character_links_schema(),
      CharacterLinksResponse:
        response_schema(
          Schema.ref(:CharacterLinksData),
          "Character Links Response",
          "Response containing character links"
        ),
      Faction: faction_schema(),
      FactionCreateParams: faction_create_params_schema(),
      FactionUpdateParams: faction_update_params_schema(),
      FactionCreateRequest: faction_create_request_schema(),
      FactionUpdateRequest: faction_update_request_schema(),
      FactionResponse:
        response_schema(
          Schema.ref(:Faction),
          "Faction Response",
          "Response containing a single faction"
        ),
      FactionsResponse:
        array_response_schema(
          :Faction,
          "Factions Response",
          "Response containing a list of factions"
        ),
      FactionLinksData: faction_links_data_schema(),
      FactionLinks: faction_links_schema(),
      FactionLinksResponse:
        response_schema(
          Schema.ref(:FactionLinksData),
          "Faction Links Response",
          "Response containing faction links"
        ),
      LinkRequest: link_request_schema(),
      Location: location_schema(),
      LocationCreateParams: location_create_params_schema(),
      LocationUpdateParams: location_update_params_schema(),
      LocationCreateRequest: location_create_request_schema(),
      LocationUpdateRequest: location_update_request_schema(),
      LocationResponse:
        response_schema(
          Schema.ref(:Location),
          "Location Response",
          "Response containing a single location"
        ),
      LocationsResponse:
        array_response_schema(
          :Location,
          "Locations Response",
          "Response containing a list of locations"
        ),
      LocationLinksData: location_links_data_schema(),
      LocationLinks: location_links_schema(),
      LocationLinksResponse:
        response_schema(
          Schema.ref(:LocationLinksData),
          "Location Links Response",
          "Response containing location links"
        ),
      Quest: quest_schema(),
      QuestCreateParams: quest_create_params_schema(),
      QuestUpdateParams: quest_update_params_schema(),
      QuestCreateRequest: quest_create_request_schema(),
      QuestUpdateRequest: quest_update_request_schema(),
      QuestResponse:
        response_schema(
          Schema.ref(:Quest),
          "Quest Response",
          "Response containing a single quest"
        ),
      QuestsResponse:
        array_response_schema(:Quest, "Quests Response", "Response containing a list of quests"),
      QuestLinksData: quest_links_data_schema(),
      QuestLinks: quest_links_schema(),
      QuestLinksResponse:
        response_schema(
          Schema.ref(:QuestLinksData),
          "Quest Links Response",
          "Response containing quest links"
        ),
      Entities: entities_schema(),
      EntitiesData: entities_data_schema(),
      EntitiesResponse:
        response_schema(
          Schema.ref(:EntitiesData),
          "Entities Response",
          "Response containing all game entities"
        ),
      Error: error_schema(),
      ErrorDetails: error_details_schema(),
      User: user_schema(),
      LoginRequest: login_request_schema(),
      LoginResponse: login_response_schema(),
      AuthStatusResponse: auth_status_response_schema(),
      SignupRequest: signup_request_schema()
    }
  end
end
