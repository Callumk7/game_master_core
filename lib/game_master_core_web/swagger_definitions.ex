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
        content(:string, "Game content")
        content_plain_text(:string, "Game content as plain text")
        setting(:string, "Game setting")
        owner_id(:string, "Owner user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "123e4567-e89b-12d3-a456-426614174000",
        name: "My Campaign",
        content: "An epic adventure",
        content_plain_text: "An epic adventure",
        setting: "Fantasy",
        owner_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Game content")
        content_plain_text(:string, "Game content as plain text")
        setting(:string, "Game setting")
      end

      required([:name])

      example(%{
        name: "My Campaign",
        content: "An epic adventure",
        content_plain_text: "An epic adventure",
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
        content(:string, "Game content")
        content_plain_text(:string, "Game content as plain text")
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
        user_id(:string, "User ID", required: true, format: :uuid)
        email(:string, "User email", required: true)
        role(:string, "Member role", required: true)
        joined_at(:string, "Join timestamp", format: :datetime)
      end

      example(%{
        user_id: "123e4567-e89b-12d3-a456-426614174000",
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
        content(:string, "Note content")
        content_plain_text(:string, "Note content as plain text")
        tags(Schema.array(:string), "Tags associated with this note")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "223e4567-e89b-12d3-a456-426614174001",
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        content_plain_text:
          "The dragon is hiding in the crystal cave beyond the misty mountains.",
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
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        tags(Schema.array(:string), "Tags associated with this character")
        member_of_faction_id(:string, "ID of faction this character belongs to", format: :uuid)
        faction_role(:string, "Role within the faction")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "323e4567-e89b-12d3-a456-426614174002",
        name: "Gandalf the Grey",
        content: "A wise and powerful wizard who guides the Fellowship.",
        content_plain_text: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        tags: ["npc", "ally", "wizard"],
        member_of_faction_id: "423e4567-e89b-12d3-a456-426614174003",
        faction_role: "Elder Council Member",
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
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(Schema.array(:string), "Tags associated with this faction")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "423e4567-e89b-12d3-a456-426614174003",
        name: "The Shadow Council",
        content:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        content_plain_text:
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
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")

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
        content: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        content_plain_text:
          "A mysterious cave hidden in the mountains, known for its glowing crystals.",
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
        content(:string, "Quest content")
        content_plain_text(:string, "Quest content as plain text")
        tags(Schema.array(:string), "Tags associated with this quest")
        parent_id(:string, "Parent quest ID for hierarchical structure", format: :uuid)

        status(:string, "Quest status",
          required: true,
          enum: ["preparing", "ready", "active", "paused", "completed", "cancelled"]
        )

        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "623e4567-e89b-12d3-a456-426614174005",
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        content_plain_text: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure", "exploration"],
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        status: "preparing",
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
        notes(Schema.array(:Note), "Notes list")
        characters(Schema.array(:Character), "Characters list")
        factions(Schema.array(:Faction), "Factions list")
        locations(Schema.array(:Location), "Locations list")
        quests(Schema.array(:Quest), "Quests list")
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
        content(:string, "Note content")
        content_plain_text(:string, "Note content as plain text")
        tags(Schema.array(:string), "Tags associated with this note")
        parent_id(:string, "Parent ID (note or other entity)", format: :uuid)

        parent_type(:string, "Type of parent entity (character, quest, location, faction)",
          enum: ["character", "quest", "location", "faction"]
        )

        pinned(:boolean, "Whether this note is pinned", required: true)
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:string, "Author user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "223e4567-e89b-12d3-a456-426614174001",
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        content_plain_text:
          "The dragon is hiding in the crystal cave beyond the misty mountains.",
        tags: ["important", "dragon", "quest"],
        pinned: false,
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Note content")
        content_plain_text(:string, "Note content as plain text")
        tags(Schema.array(:string), "Tags for this note")
        parent_id(:string, "Parent ID (note or other entity)", format: :uuid)

        parent_type(:string, "Type of parent entity (character, quest, location, faction)",
          enum: ["character", "quest", "location", "faction"]
        )
      end

      required([:name])

      example(%{
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        content_plain_text:
          "The dragon is hiding in the crystal cave beyond the misty mountains.",
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
        content_plain_text(:string, "Note content as plain text")
        tags(Schema.array(:string), "Tags for this note")
        parent_id(:string, "Parent ID (note or other entity)", format: :uuid, nullable: true)

        parent_type(:string, "Type of parent entity (character, quest, location, faction)",
          enum: ["character", "quest", "location", "faction"]
        )

        pinned(:boolean, "Whether this note is pinned")
      end

      example(%{
        name: "Updated Quest Notes",
        pinned: true
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
        characters(Schema.array(:LinkedCharacter), "Linked characters with metadata")
        factions(Schema.array(:LinkedFaction), "Linked factions with metadata")
        locations(Schema.array(:LinkedLocation), "Linked locations with metadata")
        quests(Schema.array(:LinkedQuest), "Linked quests with metadata")
        notes(Schema.array(:LinkedNote), "Linked notes with metadata")
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
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        tags(Schema.array(:string), "Tags associated with this character")
        member_of_faction_id(:string, "ID of faction this character belongs to", format: :uuid)
        faction_role(:string, "Role within the faction")
        pinned(:boolean, "Whether this character is pinned", required: true)
        race(:string, "Character race")
        alive(:boolean, "Whether this character is alive", required: true)
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:string, "Creator user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "323e4567-e89b-12d3-a456-426614174002",
        name: "Gandalf the Grey",
        content: "A wise and powerful wizard who guides the Fellowship.",
        content_plain_text: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        tags: ["npc", "ally", "wizard"],
        member_of_faction_id: "423e4567-e89b-12d3-a456-426614174003",
        faction_role: "Elder Council Member",
        pinned: false,
        race: "Maiar",
        alive: true,
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        tags(Schema.array(:string), "Tags for this character")
        member_of_faction_id(:string, "ID of faction this character belongs to", format: :uuid)
        faction_role(:string, "Role within the faction")
        race(:string, "Character race")
        alive(:boolean, "Whether this character is alive")
      end

      required([:name, :class, :level])

      example(%{
        name: "Gandalf the Grey",
        content: "A wise and powerful wizard who guides the Fellowship.",
        content_plain_text: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        tags: ["npc", "ally", "wizard"],
        member_of_faction_id: "423e4567-e89b-12d3-a456-426614174003",
        faction_role: "Elder Council Member",
        race: "Maiar",
        alive: true
      })
    end
  end

  def character_update_params_schema do
    swagger_schema do
      title("Character Update Parameters")
      description("Parameters for updating an existing character (partial updates supported)")

      properties do
        name(:string, "Character name")
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        class(:string, "Character class")
        level(:integer, "Character level")
        tags(Schema.array(:string), "Tags for this character")
        member_of_faction_id(:string, "ID of faction this character belongs to", format: :uuid)
        faction_role(:string, "Role within the faction")
        pinned(:boolean, "Whether this character is pinned")
        race(:string, "Character race")
        alive(:boolean, "Whether this character is alive")
      end

      example(%{
        level: 21,
        content: "A wise and powerful wizard who guides the Fellowship through many perils.",
        content_plain_text:
          "A wise and powerful wizard who guides the Fellowship through many perils.",
        faction_role: "Elder Council Leader",
        pinned: true,
        race: "Maiar",
        alive: false
      })
    end
  end

  def character_creation_link_schema do
    swagger_schema do
      title("Character Creation Link")
      description("Link definition for character creation")

      properties do
        entity_type(:string, "Entity type to link",
          required: true,
          enum: ["character", "faction", "location", "quest", "note"]
        )

        entity_id(:string, "Entity ID to link", required: true, format: :uuid)

        relationship_type(:string, "Type of relationship between entities", required: false)

        description(:string, "Free-form description of the relationship", required: false)

        strength(:integer, "Relationship strength/importance (1-10)",
          required: false,
          minimum: 1,
          maximum: 10
        )

        is_active(:boolean, "Whether the relationship is currently active",
          required: false,
          default: true
        )

        is_current_location(:boolean, "Whether this is the character's current location (location links only)",
          required: false,
          default: false
        )

        is_primary(:boolean, "Whether this is the character's primary faction (faction links only)",
          required: false,
          default: false
        )

        faction_role(:string, "Character's role in the faction (faction links only)", required: false)

        metadata(:object, "Additional flexible metadata as JSON", required: false)
      end

      required([:entity_type, :entity_id])

      example(%{
        entity_type: "faction",
        entity_id: "423e4567-e89b-12d3-a456-426614174003",
        is_primary: true,
        faction_role: "Leader",
        relationship_type: "member",
        strength: 8,
        is_active: true
      })
    end
  end

  def character_create_request_schema do
    swagger_schema do
      title("Character Create Request")
      description("Character creation parameters with optional entity links")

      properties do
        character(Schema.ref(:CharacterCreateParams), "Character parameters")
        links(Schema.array(:CharacterCreationLink), "Optional links to other entities", required: false)
      end

      required([:character])

      example(%{
        character: %{
          name: "Aragorn",
          class: "Ranger",
          level: 20,
          content: "Heir of Isildur, rightful king of Gondor",
          race: "Human"
        },
        links: [
          %{
            entity_type: "faction",
            entity_id: "423e4567-e89b-12d3-a456-426614174003",
            is_primary: true,
            faction_role: "Leader",
            relationship_type: "member"
          }
        ]
      })
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
        notes(Schema.array(:LinkedNote), "Linked notes with metadata")
        factions(Schema.array(:LinkedFactionWithPrimary), "Linked factions with metadata")
        locations(Schema.array(:LinkedLocationWithCurrent), "Linked locations with metadata")
        quests(Schema.array(:LinkedQuest), "Linked quests with metadata")
        characters(Schema.array(:LinkedCharacter), "Linked characters with metadata")
      end
    end
  end

  def character_notes_tree_data_schema do
    swagger_schema do
      title("Character Notes Tree Data")
      description("Hierarchical tree of notes associated with a character")

      properties do
        character_id(:string, "Character ID", required: true, format: :uuid)
        character_name(:string, "Character name", required: true)
        notes_tree(Schema.array(:NoteTreeNode), "Hierarchical notes tree")
      end
    end
  end

  def faction_notes_tree_data_schema do
    swagger_schema do
      title("Faction Notes Tree Data")
      description("Hierarchical tree of notes associated with a faction")

      properties do
        faction_id(:string, "Faction ID", required: true, format: :uuid)
        faction_name(:string, "Faction name", required: true)
        notes_tree(Schema.array(:NoteTreeNode), "Hierarchical notes tree")
      end
    end
  end

  def note_tree_node_schema do
    swagger_schema do
      title("Note Tree Node")
      description("A node in the note hierarchy tree")

      properties do
        id(:string, "Note ID", required: true, format: :uuid)
        name(:string, "Note name", required: true)
        content(:string, "Note content")
        content_plain_text(:string, "Note content as plain text")
        tags(Schema.array(:string), "Tags associated with this note")
        parent_id(:string, "Parent ID (note or other entity)", format: :uuid)

        parent_type(:string, "Type of parent entity (character, quest, location, faction)",
          enum: ["character", "quest", "location", "faction"]
        )

        entity_type(:string, "Entity type for URL building", required: true, enum: ["note"])
        children(Schema.array(:NoteTreeNode), "Child notes")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "723e4567-e89b-12d3-a456-426614174006",
        name: "Character Backstory",
        content: "Detailed backstory information...",
        content_plain_text: "Detailed backstory information...",
        tags: ["backstory", "important"],
        parent_id: "523e4567-e89b-12d3-a456-426614174004",
        parent_type: "Character",
        entity_type: "note",
        children: [
          %{
            id: "823e4567-e89b-12d3-a456-426614174007",
            name: "Childhood Memories",
            content: "Early life details...",
            entity_type: "note",
            children: []
          }
        ],
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z"
      })
    end
  end

  def faction_schema do
    swagger_schema do
      title("Faction")
      description("A game faction")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        images(Schema.array(:Image), "All images associated with this faction")
        tags(Schema.array(:string), "Tags associated with this faction")
        pinned(:boolean, "Whether this faction is pinned", required: true)
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:string, "Creator user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "423e4567-e89b-12d3-a456-426614174003",
        name: "The Shadow Council",
        content:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        content_plain_text:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        tags: ["secret", "political", "antagonist"],
        pinned: false,
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(Schema.array(:string), "Tags for this faction")
      end

      required([:name])

      example(%{
        name: "The Shadow Council",
        content:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        content_plain_text:
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
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(Schema.array(:string), "Tags for this faction")
        pinned(:boolean, "Whether this faction is pinned")
      end

      example(%{
        content:
          "A secretive organization that seeks to control the entire realm from behind the scenes, now with expanded influence.",
        content_plain_text:
          "A secretive organization that seeks to control the entire realm from behind the scenes, now with expanded influence.",
        pinned: false
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
        notes(Schema.array(:LinkedNote), "Linked notes with metadata")
        characters(Schema.array(:LinkedCharacterWithPrimary), "Linked characters with metadata")
        locations(Schema.array(:LinkedLocationWithCurrent), "Linked locations with metadata")
        quests(Schema.array(:LinkedQuest), "Linked quests with metadata")
        factions(Schema.array(:LinkedFaction), "Linked factions with metadata")
      end
    end
  end

  def faction_members_data_schema do
    swagger_schema do
      title("Faction Members Data")
      description("Characters that are members of a faction")

      properties do
        faction_id(:string, "Faction ID", required: true, format: :uuid)
        faction_name(:string, "Faction name", required: true)
        members(Schema.array(:Character), "Faction member characters")
      end

      example(%{
        faction_id: "423e4567-e89b-12d3-a456-426614174003",
        faction_name: "The White Council",
        members: [
          %{
            id: "123e4567-e89b-12d3-a456-426614174000",
            name: "Gandalf the Grey",
            class: "Wizard",
            level: 20,
            member_of_faction_id: "423e4567-e89b-12d3-a456-426614174003",
            faction_role: "Elder Council Member"
          }
        ]
      })
    end
  end

  def link_request_schema do
    swagger_schema do
      title("Link Request")
      description("Request to create a link between entities")

      properties do
        entity_type(:string, "Entity type to link",
          required: true,
          enum: ["character", "faction", "location", "quest", "note"]
        )

        entity_id(:string, "Entity ID to link", required: true, format: :uuid)

        relationship_type(:string, "Type of relationship between entities", required: false)

        description(:string, "Free-form description of the relationship", required: false)

        strength(:integer, "Relationship strength/importance (1-10)",
          required: false,
          minimum: 1,
          maximum: 10
        )

        is_active(:boolean, "Whether the relationship is currently active",
          required: false,
          default: true
        )

        metadata(:object, "Additional flexible metadata as JSON", required: false)
      end

      required([:entity_type, :entity_id])

      example(%{
        entity_type: "character",
        entity_id: "323e4567-e89b-12d3-a456-426614174002",
        relationship_type: "ally",
        description: "Long-time allies from the war",
        strength: 8,
        is_active: true,
        metadata: %{
          "since" => "2021-01-01",
          "notes" => "Met during the siege"
        }
      })
    end
  end

  def link_update_request_schema do
    swagger_schema do
      title("Link Update Request")
      description("Request to update link metadata between entities")

      properties do
        relationship_type(:string, "Type of relationship between entities", required: false)
        description(:string, "Free-form description of the relationship", required: false)

        strength(:integer, "Relationship strength/importance (1-10)",
          required: false,
          minimum: 1,
          maximum: 10
        )

        is_active(:boolean, "Whether the relationship is currently active", required: false)
        metadata(:object, "Additional flexible metadata as JSON", required: false)
      end

      example(%{
        relationship_type: "enemy",
        description: "Former allies turned enemies",
        strength: 9,
        is_active: false,
        metadata: %{
          "changed_on" => "2021-06-15",
          "reason" => "Betrayal during the council meeting"
        }
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
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:string, "Parent location ID", format: :uuid)
        images(Schema.array(:Image), "All images associated with this location")
        tags(Schema.array(:string), "Tags associated with this location")
        pinned(:boolean, "Whether this location is pinned", required: true)
        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:string, "Creator user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "523e4567-e89b-12d3-a456-426614174004",
        name: "The Crystal Cave",
        content: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        content_plain_text:
          "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        tags: ["magical", "hidden", "dangerous"],
        pinned: false,
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")

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
        content: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        content_plain_text:
          "A mysterious cave hidden in the mountains, known for its glowing crystals.",
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
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")

        type(:string, "Location type",
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:string, "Parent location ID", format: :uuid)
        tags(Schema.array(:string), "Tags for this location")
        pinned(:boolean, "Whether this location is pinned")
      end

      example(%{
        content:
          "A mysterious cave hidden deep in the mountains, known for its brilliant glowing crystals and ancient runes.",
        content_plain_text:
          "A mysterious cave hidden deep in the mountains, known for its brilliant glowing crystals and ancient runes.",
        pinned: true
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
        notes(Schema.array(:LinkedNote), "Linked notes with metadata")

        characters(
          Schema.array(:LinkedCharacterWithCurrentLocation),
          "Linked characters with metadata"
        )

        factions(Schema.array(:LinkedFactionWithCurrentLocation), "Linked factions with metadata")
        quests(Schema.array(:LinkedQuest), "Linked quests with metadata")
        locations(Schema.array(:LinkedLocation), "Linked locations with metadata")
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
        content(:string, "Quest content")
        content_plain_text(:string, "Quest content as plain text")
        images(Schema.array(:Image), "All images associated with this quest")
        tags(Schema.array(:string), "Tags associated with this quest")
        parent_id(:string, "Parent quest ID for hierarchical structure", format: :uuid)
        pinned(:boolean, "Whether this quest is pinned", required: true)

        status(:string, "Quest status",
          required: true,
          enum: ["preparing", "ready", "active", "paused", "completed", "cancelled"]
        )

        game_id(:string, "Associated game ID", required: true, format: :uuid)
        user_id(:string, "Creator user ID", required: true, format: :uuid)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: "623e4567-e89b-12d3-a456-426614174005",
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        content_plain_text: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure", "exploration"],
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        pinned: false,
        status: "preparing",
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        user_id: "123e4567-e89b-12d3-a456-426614174001",
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
        content(:string, "Quest content")
        content_plain_text(:string, "Quest content as plain text")
        tags(Schema.array(:string), "Tags for this quest")
        parent_id(:string, "Parent quest ID for hierarchical structure", format: :uuid)

        status(:string, "Quest status",
          enum: ["preparing", "ready", "active", "paused", "completed", "cancelled"]
        )
      end

      required([:name])

      example(%{
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        content_plain_text: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure"],
        parent_id: "723e4567-e89b-12d3-a456-426614174006"
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
        content_plain_text(:string, "Quest content as plain text")
        tags(Schema.array(:string), "Tags for this quest")
        parent_id(:string, "Parent quest ID for hierarchical structure", format: :uuid)
        pinned(:boolean, "Whether this quest is pinned")

        status(:string, "Quest status",
          enum: ["preparing", "ready", "active", "paused", "completed", "cancelled"]
        )
      end

      example(%{
        content:
          "Find the lost treasure hidden deep within the ancient ruins beneath the Crystal Cave. Beware of the guardian spirits.",
        content_plain_text:
          "Find the lost treasure hidden deep within the ancient ruins beneath the Crystal Cave. Beware of the guardian spirits.",
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        pinned: false
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
        notes(Schema.array(:LinkedNote), "Linked notes with metadata")
        characters(Schema.array(:LinkedCharacter), "Linked characters with metadata")
        factions(Schema.array(:LinkedFaction), "Linked factions with metadata")
        locations(Schema.array(:LinkedLocation), "Linked locations with metadata")
        quests(Schema.array(:LinkedQuest), "Linked quests with metadata")
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
        id(:string, "User ID", required: true, format: :uuid)
        email(:string, "User email", required: true)
        confirmed_at(:string, "Email confirmation timestamp", format: :datetime)
      end

      example(%{
        id: "123e4567-e89b-12d3-a456-426614174001",
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
          id: "123e4567-e89b-12d3-a456-426614174001",
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
          id: "123e4567-e89b-12d3-a456-426614174001",
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

  def location_tree_node_schema do
    swagger_schema do
      title("Location Tree Node")
      description("A node in the location hierarchy tree")

      properties do
        id(:string, "Location ID", required: true, format: :uuid)
        name(:string, "Location name", required: true)
        content(:string, "Location content")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        tags(Schema.array(:string), "Tags associated with this location")
        parent_id(:string, "Parent location ID", format: :uuid)
        entity_type(:string, "Entity type for URL building", required: true, enum: ["location"])
        children(Schema.array(:LocationTreeNode), "Child locations")
      end

      example(%{
        id: "523e4567-e89b-12d3-a456-426614174004",
        name: "The Crystal Cave",
        content: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        tags: ["magical", "hidden", "dangerous"],
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        entity_type: "location",
        children: []
      })
    end
  end

  def quest_tree_node_schema do
    swagger_schema do
      title("Quest Tree Node")
      description("A node in the quest hierarchy tree")

      properties do
        id(:string, "Quest ID", required: true, format: :uuid)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content")
        content_plain_text(:string, "Quest content as plain text")
        tags(Schema.array(:string), "Tags associated with this quest")
        parent_id(:string, "Parent quest ID", format: :uuid)

        status(:string, "Quest status",
          required: true,
          enum: ["preparing", "ready", "active", "paused", "completed", "cancelled"]
        )

        entity_type(:string, "Entity type for URL building", required: true, enum: ["quest"])
        children(Schema.array(:QuestTreeNode), "Child quests")
      end

      example(%{
        id: "623e4567-e89b-12d3-a456-426614174005",
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        content_plain_text: "Find the lost treasure hidden in the ancient ruins.",
        tags: ["main", "treasure", "exploration"],
        parent_id: "723e4567-e89b-12d3-a456-426614174006",
        status: "preparing",
        entity_type: "quest",
        children: []
      })
    end
  end

  # Linked entity schemas with metadata
  def linked_entity_base_schema do
    swagger_schema do
      properties do
        relationship_type(:string, "Type of relationship", required: false)
        description(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_character_schema do
    swagger_schema do
      title("Linked Character")
      description("A character with relationship metadata")

      properties do
        id(:string, "Character ID", required: true, format: :uuid)
        name(:string, "Character name", required: true)
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        tags(:array, "Character tags")

        member_of_faction_id(:string, "ID of faction this character belongs to",
          format: :uuid,
          required: false
        )

        faction_role(:string, "Role within the faction", required: false)
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_character_with_primary_schema do
    swagger_schema do
      title("Linked Character")
      description("A character with relationship metadata")

      properties do
        id(:string, "Character ID", required: true, format: :uuid)
        name(:string, "Character name", required: true)
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        tags(:array, "Character tags")

        member_of_faction_id(:string, "ID of faction this character belongs to",
          format: :uuid,
          required: false
        )

        faction_role(:string, "Role within the faction", required: false)
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        is_primary(:boolean, "Whether the relationship is primary", required: false)
        faction_role(:string, "Role within the faction", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_character_with_current_location_schema do
    swagger_schema do
      title("Linked Character")
      description("A character with relationship metadata")

      properties do
        id(:string, "Character ID", required: true, format: :uuid)
        name(:string, "Character name", required: true)
        content(:string, "Character content")
        content_plain_text(:string, "Character content as plain text")
        tags(:array, "Character tags")

        member_of_faction_id(:string, "ID of faction this character belongs to",
          format: :uuid,
          required: false
        )

        faction_role(:string, "Role within the faction", required: false)
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)

        is_current_location(:boolean, "Whether the location is the current location",
          required: false
        )

        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_faction_schema do
    swagger_schema do
      title("Linked Faction")
      description("A faction with relationship metadata")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(:array, "Faction tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_faction_with_primary_schema do
    swagger_schema do
      title("Linked Faction")
      description("A faction with relationship metadata")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(:array, "Faction tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        is_primary(:boolean, "Whether the relationship is primary", required: false)
        faction_role(:string, "Role within the faction", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_faction_with_current_location_schema do
    swagger_schema do
      title("Linked Faction")
      description("A faction with relationship metadata")

      properties do
        id(:string, "Faction ID", required: true, format: :uuid)
        name(:string, "Faction name", required: true)
        content(:string, "Faction content")
        content_plain_text(:string, "Faction content as plain text")
        tags(:array, "Faction tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)

        is_current_location(:boolean, "Whether the location is the current location",
          required: false
        )

        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_location_schema do
    swagger_schema do
      title("Linked Location")
      description("A location with relationship metadata")

      properties do
        id(:string, "Location ID", required: true, format: :uuid)
        name(:string, "Location name", required: true)
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")
        tags(:array, "Location tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_location_with_current_schema do
    swagger_schema do
      title("Linked Location")
      description("A location with relationship metadata")

      properties do
        id(:string, "Location ID", required: true, format: :uuid)
        name(:string, "Location name", required: true)
        content(:string, "Location content")
        content_plain_text(:string, "Location content as plain text")
        tags(:array, "Location tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)

        is_current_location(:boolean, "Whether the location is the current location",
          required: false
        )

        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_quest_schema do
    swagger_schema do
      title("Linked Quest")
      description("A quest with relationship metadata")

      properties do
        id(:string, "Quest ID", required: true, format: :uuid)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content")
        content_plain_text(:string, "Quest content as plain text")
        tags(:array, "Quest tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def linked_note_schema do
    swagger_schema do
      title("Linked Note")
      description("A note with relationship metadata")

      properties do
        id(:string, "Note ID", required: true, format: :uuid)
        name(:string, "Note name", required: true)
        content(:string, "Note content")
        content_plain_text(:string, "Note content as plain text")
        tags(:array, "Note tags")
        relationship_type(:string, "Type of relationship", required: false)
        description_meta(:string, "Description of the relationship", required: false)
        strength(:integer, "Relationship strength (1-10)", required: false)
        is_active(:boolean, "Whether the relationship is active", required: false)
        metadata(:object, "Additional metadata", required: false)
      end
    end
  end

  def set_primary_faction_request_schema do
    swagger_schema do
      title("Set Primary Faction Request")
      description("Parameters for setting a character's primary faction")

      properties do
        faction_id(:string, "Faction ID", required: true, format: :uuid)
        role(:string, "Character's role in the faction", required: true)
      end

      required([:faction_id, :role])

      example(%{
        faction_id: "423e4567-e89b-12d3-a456-426614174003",
        role: "Captain"
      })
    end
  end

  def character_primary_faction_data_schema do
    swagger_schema do
      title("Character Primary Faction Data")
      description("Primary faction information for a character")

      properties do
        character_id(:string, "Character ID", required: true, format: :uuid)
        faction(Schema.ref(:Faction), "Faction details", required: true)
        role(:string, "Character's role in the faction", required: true)
      end

      example(%{
        character_id: "323e4567-e89b-12d3-a456-426614174002",
        faction: %{
          id: "423e4567-e89b-12d3-a456-426614174003",
          name: "The Grey Council",
          content: "A council of wise beings...",
          content_plain_text: "A council of wise beings...",
          tags: ["council", "wisdom"]
        },
        role: "Elder Council Member"
      })
    end
  end

  def pinned_entities_schema do
    swagger_schema do
      title("Pinned Entities")
      description("Collection of pinned entities grouped by type")

      properties do
        characters(Schema.array(:Character), "Pinned characters")
        notes(Schema.array(:Note), "Pinned notes")
        factions(Schema.array(:Faction), "Pinned factions")
        locations(Schema.array(:Location), "Pinned locations")
        quests(Schema.array(:Quest), "Pinned quests")
      end
    end
  end

  def pinned_entities_data_schema do
    swagger_schema do
      title("Pinned Entities Data")
      description("All pinned entities for a game")

      properties do
        game_id(:string, "Game ID", required: true, format: :uuid)
        total_count(:integer, "Total number of pinned entities", required: true)

        pinned_entities(Schema.ref(:PinnedEntities), "Pinned entities grouped by type",
          required: true
        )
      end

      example(%{
        game_id: "123e4567-e89b-12d3-a456-426614174000",
        total_count: 3,
        pinned_entities: %{
          characters: [
            %{
              id: "456e7890-e89b-12d3-a456-426614174001",
              name: "Hero Character",
              pinned: true
            }
          ],
          notes: [
            %{
              id: "789e1234-e89b-12d3-a456-426614174002",
              name: "Important Note",
              pinned: true
            }
          ],
          factions: [],
          locations: [],
          quests: []
        }
      })
    end
  end

  def entity_tree_node_schema do
    swagger_schema do
      title("Entity Tree Node")
      description("A single node in the entity relationship tree")

      properties do
        id(:string, "Entity ID", required: true, format: :uuid)
        name(:string, "Entity name", required: true)

        type(:string, "Entity type",
          required: true,
          enum: ["character", "faction", "location", "quest", "note"]
        )

        relationship_type(:string, "Type of relationship to parent", required: false)
        description(:string, "Relationship description", required: false)
        strength(:integer, "Relationship strength (1-5)", required: false, minimum: 1, maximum: 5)
        is_active(:boolean, "Whether relationship is active", required: false)
        metadata(:object, "Additional relationship metadata", required: false)
        children(Schema.array(:EntityTreeNode), "Child entities", required: true)
      end

      example(%{
        id: "123e4567-e89b-12d3-a456-426614174000",
        name: "Main Character",
        type: "character",
        relationship_type: "friend",
        description: "Close friend and ally",
        strength: 4,
        is_active: true,
        metadata: %{notes: "Met during quest"},
        children: [
          %{
            id: "456e7890-e89b-12d3-a456-426614174001",
            name: "Character's Faction",
            type: "faction",
            relationship_type: "member",
            description: "Active member",
            strength: 3,
            is_active: true,
            metadata: %{},
            children: []
          }
        ]
      })
    end
  end

  def entity_tree_data_schema do
    swagger_schema do
      title("Entity Tree Data")
      description("Entity relationship tree data grouped by entity types or single tree")

      properties do
        characters(Schema.array(:EntityTreeNode), "Character trees", required: false)
        factions(Schema.array(:EntityTreeNode), "Faction trees", required: false)
        locations(Schema.array(:EntityTreeNode), "Location trees", required: false)
        quests(Schema.array(:EntityTreeNode), "Quest trees", required: false)
        notes(Schema.array(:EntityTreeNode), "Note trees", required: false)
      end

      example(%{
        characters: [
          %{
            id: "123e4567-e89b-12d3-a456-426614174000",
            name: "Main Character",
            type: "character",
            children: []
          }
        ],
        factions: [],
        locations: [],
        quests: [],
        notes: []
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
      CharacterCreationLink: character_creation_link_schema(),
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
      CharacterNotesTreeData: character_notes_tree_data_schema(),
      CharacterNotesTreeResponse:
        response_schema(
          Schema.ref(:CharacterNotesTreeData),
          "Character Notes Tree Response",
          "Response containing character notes tree"
        ),
      NoteTreeNode: note_tree_node_schema(),
      FactionNotesTreeData: faction_notes_tree_data_schema(),
      FactionNotesTreeResponse:
        response_schema(
          Schema.ref(:FactionNotesTreeData),
          "Faction Notes Tree Response",
          "Response containing faction notes tree"
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
      FactionMembersData: faction_members_data_schema(),
      FactionMembersResponse:
        response_schema(
          Schema.ref(:FactionMembersData),
          "Faction Members Response",
          "Response containing faction members"
        ),
      LinkRequest: link_request_schema(),
      LinkUpdateRequest: link_update_request_schema(),
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
      LocationTreeNode: location_tree_node_schema(),
      LocationTreeResponse:
        array_response_schema(
          :LocationTreeNode,
          "Location Tree Response",
          "Response containing hierarchical location tree"
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
      QuestTreeNode: quest_tree_node_schema(),
      QuestTreeResponse:
        array_response_schema(
          :QuestTreeNode,
          "Quest Tree Response",
          "Response containing hierarchical quest tree"
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
      SignupRequest: signup_request_schema(),
      # Linked entity schemas with relationship metadata
      LinkedEntityBase: linked_entity_base_schema(),
      LinkedCharacter: linked_character_schema(),
      LinkedCharacterWithCurrentLocation: linked_character_with_current_location_schema(),
      LinkedCharacterWithPrimary: linked_character_with_primary_schema(),
      LinkedFaction: linked_faction_schema(),
      LinkedFactionWithCurrentLocation: linked_faction_with_current_location_schema(),
      LinkedFactionWithPrimary: linked_faction_with_primary_schema(),
      LinkedLocation: linked_location_schema(),
      LinkedLocationWithCurrent: linked_location_with_current_schema(),
      LinkedQuest: linked_quest_schema(),
      LinkedNote: linked_note_schema(),
      # Primary faction schemas
      SetPrimaryFactionRequest: set_primary_faction_request_schema(),
      CharacterPrimaryFactionData: character_primary_faction_data_schema(),
      CharacterPrimaryFactionResponse:
        response_schema(
          Schema.ref(:CharacterPrimaryFactionData),
          "Character Primary Faction Response",
          "Response containing character's primary faction data"
        ),
      # Pinned entities schemas
      PinnedEntities: pinned_entities_schema(),
      PinnedEntitiesData: pinned_entities_data_schema(),
      PinnedEntitiesResponse:
        response_schema(
          Schema.ref(:PinnedEntitiesData),
          "Pinned Entities Response",
          "Response containing all pinned entities for a game"
        ),
      # Entity tree schemas
      EntityTreeNode: entity_tree_node_schema(),
      EntityTreeData: entity_tree_data_schema(),
      EntityTreeResponse:
        response_schema(
          Schema.ref(:EntityTreeData),
          "Entity Tree Response",
          "Response containing hierarchical tree of entity relationships"
        ),
      # Objective schemas
      Objective: objective_schema(),
      ObjectiveCreateParams: objective_create_params_schema(),
      ObjectiveUpdateParams: objective_update_params_schema(),
      ObjectiveCreateRequest: objective_create_request_schema(),
      ObjectiveUpdateRequest: objective_update_request_schema(),
      ObjectiveResponse:
        response_schema(
          Schema.ref(:Objective),
          "Objective Response",
          "Response containing a single objective"
        ),
      ObjectivesResponse:
        array_response_schema(
          :Objective,
          "Objectives Response",
          "Response containing a list of objectives"
        ),
      # Image schemas
      Image: image_schema(),
      ImageCreateParams: image_create_params_schema(),
      ImageUpdateParams: image_update_params_schema(),
      ImageCreateRequest: image_create_request_schema(),
      ImageUpdateRequest: image_update_request_schema(),
      ImageStats: image_stats_schema(),
      ImagesListResponse: images_list_response_schema(),
      ImageResponse:
        response_schema(
          Schema.ref(:Image),
          "Image Response",
          "Response containing a single image"
        ),
      ImageStatsResponse:
        response_schema(
          Schema.ref(:ImageStats),
          "Image Statistics Response",
          "Response containing image statistics for an entity"
        )
    }
  end

  def objective_schema do
    swagger_schema do
      title("Objective")
      description("A quest objective")

      properties do
        id(:string, "Objective ID", required: true, format: :uuid)
        body(:string, "Objective description", required: true)
        complete(:boolean, "Whether the objective is complete", required: true)
        quest_id(:string, "Quest ID", required: true, format: :uuid)
        note_link_id(:string, "Note link ID", format: :uuid)
        inserted_at(:string, "Creation timestamp", required: true, format: :"date-time")
        updated_at(:string, "Last update timestamp", required: true, format: :"date-time")
      end

      example(%{
        id: "123e4567-e89b-12d3-a456-426614174010",
        body: "Find the lost treasure",
        complete: false,
        quest_id: "123e4567-e89b-12d3-a456-426614174009",
        note_link_id: nil,
        inserted_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def objective_create_params_schema do
    swagger_schema do
      title("Objective Create Parameters")
      description("Parameters for creating a new objective")

      properties do
        body(:string, "Objective description")
        complete(:boolean, "Whether the objective is complete")
        note_link_id(:string, "Note link ID", format: :uuid)
      end

      required([:body])

      example(%{
        body: "Find the lost treasure",
        complete: false,
        note_link_id: nil
      })
    end
  end

  def objective_update_params_schema do
    swagger_schema do
      title("Objective Update Parameters")
      description("Parameters for updating an objective")

      properties do
        body(:string, "Objective description")
        complete(:boolean, "Whether the objective is complete")
        note_link_id(:string, "Note link ID", format: :uuid)
      end

      example(%{
        body: "Find the lost treasure in the ancient ruins",
        complete: true,
        note_link_id: "123e4567-e89b-12d3-a456-426614174008"
      })
    end
  end

  def objective_create_request_schema do
    swagger_schema do
      title("Objective Create Request")
      description("Request body for creating an objective")

      properties do
        objective(Schema.ref(:ObjectiveCreateParams), "Objective data")
      end

      required([:objective])
    end
  end

  def objective_update_request_schema do
    swagger_schema do
      title("Objective Update Request")
      description("Request body for updating an objective")

      properties do
        objective(Schema.ref(:ObjectiveUpdateParams), "Objective data")
      end

      required([:objective])
    end
  end

  # Image schemas

  def image_schema do
    swagger_schema do
      title("Image")
      description("An image associated with a game entity")

      properties do
        id(:string, "Image ID", required: true, format: :uuid)
        filename(:string, "Original filename", required: true)
        file_url(:string, "Publicly accessible URL to the image", required: true)
        file_size(:integer, "File size in bytes", required: true, minimum: 1)
        file_size_mb(:number, "File size in megabytes", required: true)

        content_type(:string, "MIME type of the image",
          required: true,
          enum: ["image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"]
        )

        alt_text(:string, "Alternative text for accessibility")
        is_primary(:boolean, "Whether this is the primary image for the entity", required: true)

        entity_type(:string, "Type of entity this image belongs to",
          required: true,
          enum: ["character", "faction", "location", "quest", "note"]
        )

        entity_id(:string, "ID of the entity this image belongs to",
          required: true,
          format: :uuid
        )

        metadata(:object, "Additional metadata for the image", default: %{})

        position_y(:integer, "Vertical position percentage (0-100) for banner placement",
          required: true,
          minimum: 0,
          maximum: 100,
          default: 50
        )

        inserted_at(:string, "Creation timestamp", required: true, format: :"date-time")
        updated_at(:string, "Last update timestamp", required: true, format: :"date-time")
      end

      example(%{
        id: "img-123e4567-e89b-12d3-a456-426614174000",
        filename: "hero-portrait.jpg",
        file_url: "/uploads/games/game-123/character/char-456/uuid.jpg",
        file_size: 1_048_576,
        file_size_mb: 1.0,
        content_type: "image/jpeg",
        alt_text: "Portrait of the main character",
        is_primary: true,
        entity_type: "character",
        entity_id: "char-456e7890-e89b-12d3-a456-426614174001",
        metadata: %{},
        position_y: 50,
        inserted_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def image_create_params_schema do
    swagger_schema do
      title("Image Create Parameters")
      description("Parameters for uploading a new image - multipart/form-data fields")
      type(:object)

      properties do
        file(:string, "Image file to upload", required: true, format: :binary)
        alt_text(:string, "Alternative text for accessibility")
        is_primary(:boolean, "Whether this should be the primary image for the entity")

        position_y(:integer, "Vertical position percentage (0-100) for banner placement",
          minimum: 0,
          maximum: 100,
          default: 50
        )
      end

      required([:file])

      example(%{
        file: "binary file data",
        alt_text: "Portrait of the main character",
        is_primary: true,
        position_y: 30
      })
    end
  end

  def image_update_params_schema do
    swagger_schema do
      title("Image Update Parameters")
      description("Parameters for updating image metadata")

      properties do
        alt_text(:string, "Alternative text for accessibility")
        is_primary(:boolean, "Whether this should be the primary image for the entity")

        position_y(:integer, "Vertical position percentage (0-100) for banner placement",
          minimum: 0,
          maximum: 100
        )
      end

      example(%{
        alt_text: "Updated portrait description",
        is_primary: false,
        position_y: 75
      })
    end
  end

  def image_create_request_schema do
    swagger_schema do
      title("Image Create Request")
      description("Form data for uploading an image - corresponds to image[field] format")
      type(:object)

      properties do
        image(Schema.ref(:ImageCreateParams), "Image upload parameters")
      end

      required([:image])
    end
  end

  def image_update_request_schema do
    swagger_schema do
      title("Image Update Request")
      description("Request body for updating image metadata")

      properties do
        image(Schema.ref(:ImageUpdateParams), "Image update parameters")
      end
    end
  end

  def image_stats_schema do
    swagger_schema do
      title("Image Statistics")
      description("Statistics about images for an entity")

      properties do
        entity_type(:string, "Type of entity",
          required: true,
          enum: ["character", "faction", "location", "quest"]
        )

        entity_id(:string, "ID of the entity", required: true, format: :uuid)

        total_count(:integer, "Total number of images for this entity",
          required: true,
          minimum: 0
        )

        total_size(:integer, "Total size of all images in bytes", required: true, minimum: 0)
        total_size_mb(:number, "Total size of all images in megabytes", required: true)
        has_primary(:boolean, "Whether the entity has a primary image", required: true)
      end

      example(%{
        entity_type: "character",
        entity_id: "char-456e7890-e89b-12d3-a456-426614174001",
        total_count: 3,
        total_size: 3_145_728,
        total_size_mb: 3.0,
        has_primary: true
      })
    end
  end

  def images_list_response_schema do
    swagger_schema do
      title("Images List Response")
      description("Response containing a list of images with metadata")

      properties do
        data(Schema.array(:Image), "List of images", required: true)
        meta(:object, "Response metadata", required: true)
      end

      example(%{
        data: [
          %{
            id: "img-123e4567-e89b-12d3-a456-426614174000",
            filename: "hero-portrait.jpg",
            file_url: "/uploads/games/game-123/character/char-456/uuid.jpg",
            file_size: 1_048_576,
            file_size_mb: 1.0,
            content_type: "image/jpeg",
            alt_text: "Portrait of the main character",
            is_primary: true,
            entity_type: "character",
            entity_id: "char-456e7890-e89b-12d3-a456-426614174001",
            metadata: %{},
            inserted_at: "2023-08-20T12:00:00Z",
            updated_at: "2023-08-20T12:00:00Z"
          }
        ],
        meta: %{
          entity_type: "character",
          entity_id: "char-456e7890-e89b-12d3-a456-426614174001",
          total_count: 1
        }
      })
    end
  end
end
