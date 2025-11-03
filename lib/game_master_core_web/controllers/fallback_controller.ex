defmodule GameMasterCoreWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use GameMasterCoreWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: GameMasterCoreWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: GameMasterCoreWeb.ErrorHTML, json: GameMasterCoreWeb.ErrorJSON)
    |> render(:"404")
  end

  # Handle not authorized errors
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "Unauthorized"})
  end

  # Handle character/note not found errors
  def call(conn, {:error, :character_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Character not found"})
  end

  def call(conn, {:error, :note_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Note not found"})
  end

  def call(conn, {:error, :faction_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Faction not found"})
  end

  # Handle link validation errors
  def call(conn, {:error, :missing_entity_type}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Entity type is required"})
  end

  def call(conn, {:error, :invalid_entity_type}) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Invalid entity type. Supported types: note, character, faction, location, quest"
    })
  end

  def call(conn, {:error, :missing_entity_id}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Entity ID is required"})
  end

  def call(conn, {:error, :invalid_entity_id}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid entity ID format"})
  end

  def call(conn, {:error, :unsupported_link_type}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: "Invalid entity type. Supported types: note, character, faction, location, quest"
    })
  end

  def call(conn, {:error, {:unsupported_link_type, source_type, target_type}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Linking #{source_type}s to #{target_type} is not yet supported"})
  end

  # Handle image upload errors
  def call(conn, {:error, :missing_file}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Image file is required"})
  end

  def call(conn, {:error, :invalid_upload}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid file upload"})
  end

  def call(conn, {:error, {:file_storage_failed, reason}}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Failed to store image file", details: inspect(reason)})
  end

  def call(conn, {:error, {:invalid_entity_type, entity_type}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid entity type: #{entity_type}"})
  end

  def call(conn, {:error, :no_primary_faction_to_remove}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Character does not have a primary faction to remove"})
  end
end
