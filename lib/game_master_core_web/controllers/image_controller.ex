defmodule GameMasterCoreWeb.ImageController do
  @moduledoc """
  Controller for managing images associated with game entities.

  This controller provides a generic interface for image management across
  all entity types (characters, factions, locations, quests).
  """

  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Images
  alias GameMasterCore.Images.Image
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  action_fallback GameMasterCoreWeb.FallbackController

  swagger_path :index do
    get("/api/games/{game_id}/{entity_type}s/{entity_id}/images")
    summary("List images for an entity")
    description("Retrieve all images associated with a specific game entity")
    tag("Images")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      primary_first(:query, :boolean, "Sort primary image first", required: false)
    end
    
    response(200, "Success", Schema.ref(:ImagesListResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  List all images for a specific entity.

  GET /api/games/{game_id}/{entity_type}/{entity_id}/images
  """
  def index(conn, params) do
    {entity_type, entity_id} = extract_entity_info(conn, params)
    primary_first = params["primary_first"] == "true"

    with {:ok, entity_type} <- validate_entity_type(entity_type) do
      images =
        Images.list_images_for_entity(
          conn.assigns.current_scope,
          entity_type,
          entity_id,
          primary_first: primary_first
        )

      render(conn, :index, images: images, entity_type: entity_type, entity_id: entity_id)
    end
  end

  swagger_path :create do
    post("/api/games/{game_id}/{entity_type}s/{entity_id}/images")
    summary("Upload an image for an entity")
    description("Upload a new image file and associate it with a game entity")
    tag("Images")
    consumes("multipart/form-data")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      body(:formData, Schema.ref(:ImageCreateRequest), "Image upload data", required: true)
    end
    
    response(201, "Created", Schema.ref(:ImageResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  @doc """
  Upload a new image for an entity.

  POST /api/games/{game_id}/{entity_type}/{entity_id}/images
  """
  def create(conn, %{"image" => image_params} = params) do
    {entity_type, entity_id} = extract_entity_info(conn, params)

    with {:ok, entity_type} <- validate_entity_type(entity_type),
         {:ok, upload} <- extract_upload_from_params(image_params),
         {:ok, %Image{} = image} <-
           Images.create_image_for_entity(
             conn.assigns.current_scope,
             upload,
             build_image_attrs(entity_type, entity_id, image_params)
           ) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        build_image_location_url(conn, entity_type, entity_id, image.id)
      )
      |> render(:show, image: image)
    end
  end

  swagger_path :show do
    get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
    summary("Get an image by ID")
    description("Retrieve a specific image by its ID")
    tag("Images")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      id(:path, :string, "Image ID", required: true, format: :uuid)
    end
    
    response(200, "Success", Schema.ref(:ImageResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  Get a specific image by ID.

  GET /api/games/{game_id}/{entity_type}/{entity_id}/images/{id}
  """
  def show(conn, %{"id" => image_id}) do
    with {:ok, image} <- Images.get_image_for_game(conn.assigns.current_scope, image_id) do
      render(conn, :show, image: image)
    end
  end

  swagger_path :update do
    put("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
    summary("Update image metadata")
    description("Update image metadata such as alt text and primary status")
    tag("Images")
    consumes("application/json")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
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

  @doc """
  Update image metadata.

  PUT /api/games/{game_id}/{entity_type}/{entity_id}/images/{id}
  """
  def update(conn, %{"id" => image_id} = params) do
    update_attrs = extract_update_attrs(params)

    with {:ok, image} <- Images.update_image(conn.assigns.current_scope, image_id, update_attrs) do
      render(conn, :show, image: image)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}")
    summary("Delete an image")
    description("Delete an image and remove it from storage")
    tag("Images")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      id(:path, :string, "Image ID", required: true, format: :uuid)
    end
    
    response(204, "No Content")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  Delete an image.

  DELETE /api/games/{game_id}/{entity_type}/{entity_id}/images/{id}
  """
  def delete(conn, %{"id" => image_id}) do
    with {:ok, _image} <- Images.delete_image(conn.assigns.current_scope, image_id) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :set_primary do
    put("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}/primary")
    summary("Set image as primary")
    description("Set an image as the primary image for its entity")
    tag("Images")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      id(:path, :string, "Image ID", required: true, format: :uuid)
    end
    
    response(200, "Success", Schema.ref(:ImageResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  Set an image as the primary image for its entity.

  PUT /api/games/{game_id}/{entity_type}/{entity_id}/images/{id}/primary
  """
  def set_primary(conn, %{"id" => image_id}) do
    with {:ok, image} <- Images.set_as_primary(conn.assigns.current_scope, image_id) do
      render(conn, :show, image: image)
    end
  end

  swagger_path :stats do
    get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/stats")
    summary("Get image statistics")
    description("Get statistics about images for an entity (count, total size, etc.)")
    tag("Images")
    produces("application/json")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
    end
    
    response(200, "Success", Schema.ref(:ImageStatsResponse))
    response(400, "Bad Request", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  Get image statistics for an entity.

  GET /api/games/{game_id}/{entity_type}/{entity_id}/images/stats
  """
  def stats(conn, params) do
    {entity_type, entity_id} = extract_entity_info(conn, params)

    with {:ok, entity_type} <- validate_entity_type(entity_type) do
      stats = Images.get_image_stats(conn.assigns.current_scope, entity_type, entity_id)
      render(conn, :stats, stats: stats, entity_type: entity_type, entity_id: entity_id)
    end
  end

  swagger_path :serve_file do
    get("/api/games/{game_id}/{entity_type}s/{entity_id}/images/{id}/file")
    summary("Serve image file")
    description("Serve or redirect to the actual image file")
    tag("Images")
    produces("image/*")
    
    parameters do
      game_id(:path, :string, "Game ID", required: true, format: :uuid)
      entity_type(:path, :string, "Entity type", required: true, enum: ["character", "faction", "location", "quest"])
      entity_id(:path, :string, "Entity ID", required: true, format: :uuid)
      id(:path, :string, "Image ID", required: true, format: :uuid)
    end
    
    response(302, "Redirect to image file")
    response(401, "Unauthorized", Schema.ref(:Error))
    response(404, "Not Found", Schema.ref(:Error))
  end

  @doc """
  Serve an image file directly.

  GET /api/games/{game_id}/{entity_type}/{entity_id}/images/{id}/file
  """
  def serve_file(conn, %{"id" => image_id}) do
    with {:ok, image} <- Images.get_image_for_game(conn.assigns.current_scope, image_id) do
      # For local storage, redirect to the public URL
      # For cloud storage, this could serve the file directly or redirect
      redirect(conn, external: image.file_url)
    end
  end

  # Private helper functions

  defp validate_entity_type(entity_type)
       when entity_type in ["character", "faction", "location", "quest"] do
    {:ok, entity_type}
  end

  defp validate_entity_type(entity_type) do
    {:error, {:invalid_entity_type, entity_type}}
  end

  defp extract_upload_from_params(%{"file" => upload}) when is_map(upload) do
    if upload.__struct__ == Plug.Upload do
      {:ok, upload}
    else
      {:error, :invalid_upload}
    end
  end

  defp extract_upload_from_params(_params) do
    {:error, :missing_file}
  end

  defp build_image_attrs(entity_type, entity_id, params) do
    %{
      entity_type: entity_type,
      entity_id: entity_id,
      alt_text: Map.get(params, "alt_text"),
      is_primary: Map.get(params, "is_primary", false)
    }
  end

  defp extract_update_attrs(params) do
    params
    |> Map.take(["alt_text", "is_primary"])
    |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp extract_entity_info(_conn, params) do
    # Extract entity type and ID from the route path
    # Routes are structured as: /api/games/{game_id}/{entity_type}/{entity_id}/images
    cond do
      params["character_id"] -> {"character", params["character_id"]}
      params["faction_id"] -> {"faction", params["faction_id"]}
      params["location_id"] -> {"location", params["location_id"]}
      params["quest_id"] -> {"quest", params["quest_id"]}
      true -> {nil, nil}
    end
  end

  defp build_image_location_url(conn, entity_type, entity_id, image_id) do
    game_id = conn.assigns.current_scope.game.id
    "/api/games/#{game_id}/#{entity_type}s/#{entity_id}/images/#{image_id}"
  end
end
