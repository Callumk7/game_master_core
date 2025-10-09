defmodule GameMasterCoreWeb.Swagger.ImageSwagger do
  @moduledoc """
  Swagger documentation definitions for ImageController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :index do
        get("/api/games/{game_id}/{entity_type}s/{entity_id}/images")
        summary("List images for an entity")
        description("Retrieve all images associated with a specific game entity")
        operation_id("listEntityImages")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          primary_first(:query, :boolean, "Sort primary image first", required: false)
        end

        response(200, "Success", Schema.ref(:ImagesListResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :create do
        post("/api/games/{game_id}/{entity_type}s/{entity_id}/images")
        summary("Upload an image for an entity")
        description("Upload a new image file and associate it with a game entity")
        operation_id("uploadEntityImage")
        tag("GameMaster")
        consumes("multipart/form-data")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
        end

        parameter(:"image[file]", :formData, :file, "Image file to upload", required: true)
        parameter(:"image[alt_text]", :formData, :string, "Alternative text for accessibility")

        parameter(
          :"image[is_primary]",
          :formData,
          :boolean,
          "Whether this should be the primary image"
        )

        parameter(
          :"image[position_y]",
          :formData,
          :integer,
          "Vertical position percentage (0-100) for banner placement"
        )

        response(201, "Created", Schema.ref(:ImageResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :show do
        get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
        summary("Get an image by ID")
        description("Retrieve a specific image by its ID")
        operation_id("getEntityImage")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          id(:path, :string, "Image ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:ImageResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :update do
        put("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
        summary("Update image metadata")
        description("Update image metadata such as alt text and primary status")
        operation_id("updateEntityImage")
        tag("GameMaster")
        consumes("application/json")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          id(:path, :string, "Image ID", required: true, format: :uuid)
          body(:body, Schema.ref(:ImageUpdateRequest), "Image update data", required: true)
        end

        response(200, "Success", Schema.ref(:ImageResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
        response(422, "Unprocessable Entity", Schema.ref(:Error))
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
        summary("Delete an image")
        description("Delete an image and remove it from storage")
        operation_id("deleteEntityImage")
        tag("GameMaster")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          id(:path, :string, "Image ID", required: true, format: :uuid)
        end

        response(204, "No Content")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :set_primary do
        put("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}/primary")
        summary("Set image as primary")
        description("Set an image as the primary image for its entity")
        operation_id("setEntityImageAsPrimary")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          id(:path, :string, "Image ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:ImageResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :primary do
        get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/primary")
        summary("Get primary image")
        description("Get the primary image for an entity")
        operation_id("getEntityPrimaryImage")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:ImageResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :stats do
        get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/stats")
        summary("Get image statistics")
        description("Get statistics about images for an entity (count, total size, etc.)")
        operation_id("getEntityImageStats")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
        end

        response(200, "Success", Schema.ref(:ImageStatsResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :serve_file do
        get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}/file")
        summary("Serve image file")
        description("Serve or redirect to the actual image file")
        operation_id("serveEntityImageFile")
        tag("GameMaster")
        produces("image/*")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)

          entity_type(:path, :string, "Entity type",
            required: true,
            enum: ["character", "faction", "location", "quest", "note"]
          )

          entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
          id(:path, :string, "Image ID", required: true, format: :uuid)
        end

        response(302, "Redirect to image file")
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end

      swagger_path :game_images do
        get("/api/games/{game_id}/images")
        summary("List all images for a game")
        description("Retrieve all images across all entities within a specific game")
        operation_id("listGameImages")
        tag("GameMaster")
        produces("application/json")

        parameters do
          game_id(:path, :string, "Game ID", required: true, format: :uuid)
          primary_first(:query, :boolean, "Sort primary images first", required: false)
          limit(:query, :integer, "Maximum number of results to return", required: false)

          offset(:query, :integer, "Number of results to skip for pagination",
            required: false,
            default: 0
          )
        end

        response(200, "Success", Schema.ref(:ImagesListResponse))
        response(400, "Bad Request", Schema.ref(:Error))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not Found", Schema.ref(:Error))
      end
    end
  end
end
