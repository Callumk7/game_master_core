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
        id(:integer, "Game ID", required: true)
        name(:string, "Game name", required: true)
        description(:string, "Game description")
        setting(:string, "Game setting")
        owner_id(:integer, "Owner user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "My Campaign",
        description: "An epic adventure",
        setting: "Fantasy",
        owner_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def game_params_schema do
    swagger_schema do
      title("Game Parameters")
      description("Parameters for creating or updating a game")

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

  def game_request_schema do
    swagger_schema do
      title("Game Request")
      description("Game creation/update parameters")

      properties do
        game(Schema.ref(:GameParams), "Game parameters")
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
        id(:integer, "Note ID", required: true)
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
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
        id(:integer, "Character ID", required: true)
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg",
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
        id(:integer, "Faction ID", required: true)
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes.",
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
        id(:integer, "Location ID", required: true)
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        has_parent(:boolean, "Whether this location has a parent location", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        has_parent: true,
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
        id(:integer, "Quest ID", required: true)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
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
        game_id(:integer, "Game ID", required: true)
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
        id(:integer, "Note ID", required: true)
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
        game_id(:integer, "Associated game ID", required: true)
        user_id(:integer, "Author user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains.",
        game_id: 1,
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def note_params_schema do
    swagger_schema do
      title("Note Parameters")
      description("Parameters for creating or updating a note")

      properties do
        name(:string, "Note name", required: true)
        content(:string, "Note content", required: true)
      end

      required([:name, :content])

      example(%{
        name: "Important Quest Notes",
        content: "The dragon is hiding in the crystal cave beyond the misty mountains."
      })
    end
  end

  def note_request_schema do
    swagger_schema do
      title("Note Request")
      description("Note creation/update parameters")

      properties do
        note(Schema.ref(:NoteParams), "Note parameters")
      end

      required([:note])
    end
  end

  def note_links_data_schema do
    swagger_schema do
      title("Note Links Data")
      description("Links associated with a note")

      properties do
        note_id(:integer, "Note ID", required: true)
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
      end
    end
  end

  def character_schema do
    swagger_schema do
      title("Character")
      description("A game character")

      properties do
        id(:integer, "Character ID", required: true)
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
        game_id(:integer, "Associated game ID", required: true)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg",
        game_id: 1,
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def character_params_schema do
    swagger_schema do
      title("Character Parameters")
      description("Parameters for creating or updating a character")

      properties do
        name(:string, "Character name", required: true)
        description(:string, "Character description")
        class(:string, "Character class", required: true)
        level(:integer, "Character level", required: true)
        image_url(:string, "Character image URL")
      end

      required([:name, :class, :level])

      example(%{
        name: "Gandalf the Grey",
        description: "A wise and powerful wizard who guides the Fellowship.",
        class: "Wizard",
        level: 20,
        image_url: "https://example.com/gandalf.jpg"
      })
    end
  end

  def character_request_schema do
    swagger_schema do
      title("Character Request")
      description("Character creation/update parameters")

      properties do
        character(Schema.ref(:CharacterParams), "Character parameters")
      end

      required([:character])
    end
  end

  def character_links_data_schema do
    swagger_schema do
      title("Character Links Data")
      description("Links associated with a character")

      properties do
        character_id(:integer, "Character ID", required: true)
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
      end
    end
  end

  def faction_schema do
    swagger_schema do
      title("Faction")
      description("A game faction")

      properties do
        id(:integer, "Faction ID", required: true)
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
        game_id(:integer, "Associated game ID", required: true)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes.",
        game_id: 1,
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def faction_params_schema do
    swagger_schema do
      title("Faction Parameters")
      description("Parameters for creating or updating a faction")

      properties do
        name(:string, "Faction name", required: true)
        description(:string, "Faction description", required: true)
      end

      required([:name, :description])

      example(%{
        name: "The Shadow Council",
        description:
          "A secretive organization that seeks to control the realm from behind the scenes."
      })
    end
  end

  def faction_request_schema do
    swagger_schema do
      title("Faction Request")
      description("Faction creation/update parameters")

      properties do
        faction(Schema.ref(:FactionParams), "Faction parameters")
      end

      required([:faction])
    end
  end

  def faction_links_data_schema do
    swagger_schema do
      title("Faction Links Data")
      description("Links associated with a faction")

      properties do
        faction_id(:integer, "Faction ID", required: true)
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

        entity_id(:integer, "Entity ID to link", required: true)
      end

      required([:entity_type, :entity_id])

      example(%{
        entity_type: "character",
        entity_id: 1
      })
    end
  end

  def location_schema do
    swagger_schema do
      title("Location")
      description("A game location")

      properties do
        id(:integer, "Location ID", required: true)
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:integer, "Parent location ID")
        game_id(:integer, "Associated game ID", required: true)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        parent_id: 2,
        game_id: 1,
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def location_params_schema do
    swagger_schema do
      title("Location Parameters")
      description("Parameters for creating or updating a location")

      properties do
        name(:string, "Location name", required: true)
        description(:string, "Location description")

        type(:string, "Location type",
          required: true,
          enum: ["continent", "nation", "region", "city", "settlement", "building", "complex"]
        )

        parent_id(:integer, "Parent location ID")
      end

      required([:name, :type])

      example(%{
        name: "The Crystal Cave",
        description: "A mysterious cave hidden in the mountains, known for its glowing crystals.",
        type: "building",
        parent_id: 2
      })
    end
  end

  def location_request_schema do
    swagger_schema do
      title("Location Request")
      description("Location creation/update parameters")

      properties do
        location(Schema.ref(:LocationParams), "Location parameters")
      end

      required([:location])
    end
  end

  def location_links_data_schema do
    swagger_schema do
      title("Location Links Data")
      description("Links associated with a location")

      properties do
        location_id(:integer, "Location ID", required: true)
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
      end
    end
  end

  def quest_schema do
    swagger_schema do
      title("Quest")
      description("A game quest")

      properties do
        id(:integer, "Quest ID", required: true)
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
        game_id(:integer, "Associated game ID", required: true)
        user_id(:integer, "Creator user ID", required: true)
        created_at(:string, "Creation timestamp", format: :datetime)
        updated_at(:string, "Last update timestamp", format: :datetime)
      end

      example(%{
        id: 1,
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins.",
        game_id: 1,
        user_id: 1,
        created_at: "2023-08-20T12:00:00Z",
        updated_at: "2023-08-20T12:00:00Z"
      })
    end
  end

  def quest_params_schema do
    swagger_schema do
      title("Quest Parameters")
      description("Parameters for creating or updating a quest")

      properties do
        name(:string, "Quest name", required: true)
        content(:string, "Quest content", required: true)
      end

      required([:name, :content])

      example(%{
        name: "The Lost Treasure",
        content: "Find the lost treasure hidden in the ancient ruins."
      })
    end
  end

  def quest_request_schema do
    swagger_schema do
      title("Quest Request")
      description("Quest creation/update parameters")

      properties do
        quest(Schema.ref(:QuestParams), "Quest parameters")
      end

      required([:quest])
    end
  end

  def quest_links_data_schema do
    swagger_schema do
      title("Quest Links Data")
      description("Links associated with a quest")

      properties do
        quest_id(:integer, "Quest ID", required: true)
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
      GameParams: game_params_schema(),
      GameRequest: game_request_schema(),
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
      NoteParams: note_params_schema(),
      NoteRequest: note_request_schema(),
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
      CharacterParams: character_params_schema(),
      CharacterRequest: character_request_schema(),
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
      FactionParams: faction_params_schema(),
      FactionRequest: faction_request_schema(),
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
      LocationParams: location_params_schema(),
      LocationRequest: location_request_schema(),
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
      QuestParams: quest_params_schema(),
      QuestRequest: quest_request_schema(),
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
