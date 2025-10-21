defmodule GameMasterCoreWeb.AccountController do
  @moduledoc """
  Controller for managing user account/profile operations.

  Provides endpoints for:
  - Getting and updating user profile information
  - Managing avatar uploads and deletion
  - Requesting and confirming email address changes
  """

  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Accounts
  alias GameMasterCore.Storage
  alias GameMasterCoreWeb.SwaggerDefinitions

  action_fallback GameMasterCoreWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.AccountSwagger

  @doc """
  Get the current user's profile information.

  GET /api/account/profile
  """
  def show(conn, _params) do
    user = conn.assigns.current_scope.user

    profile = %{
      id: user.id,
      email: user.email,
      username: user.username,
      avatar_url: user.avatar_url,
      confirmed_at: user.confirmed_at
    }

    json(conn, profile)
  end

  @doc """
  Update the current user's profile information.

  Currently supports username updates.

  PATCH /api/account/profile
  """
  def update(conn, %{"username" => username}) do
    user = conn.assigns.current_scope.user

    case Accounts.update_user_username(user, %{username: username}) do
      {:ok, updated_user} ->
        profile = %{
          id: updated_user.id,
          email: updated_user.email,
          username: updated_user.username,
          avatar_url: updated_user.avatar_url,
          confirmed_at: updated_user.confirmed_at
        }

        conn
        |> put_status(:ok)
        |> json(profile)

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.reduce(%{}, fn {field, {message, _}}, acc ->
            Map.put(acc, field, message)
          end)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors})
    end
  end

  @doc """
  Upload an avatar image for the current user.

  POST /api/account/avatar
  """
  def upload_avatar(conn, %{"avatar" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_scope.user

    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    unless upload.content_type in allowed_types do
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed."})
    else
      # Validate file size (5MB max)
      max_size = 5 * 1024 * 1024
      file_size = File.stat!(upload.path).size
      if file_size > max_size do
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "File too large. Maximum size is 5MB."})
      else
        # Generate storage key for user avatar
        key = "avatars/#{user.id}/#{upload.filename}"

        # Store the file
        case Storage.store(upload.path, key, content_type: upload.content_type) do
          {:ok, %{url: url}} ->
            # Clean up old avatar if it exists
            if user.avatar_url do
              # Extract old key from URL if needed
              old_key = extract_key_from_url(user.avatar_url)
              if old_key, do: Storage.delete(old_key)
            end

            # Update user with new avatar URL
            case Accounts.update_user_avatar(user, %{avatar_url: url}) do
              {:ok, updated_user} ->
                profile = %{
                  id: updated_user.id,
                  email: updated_user.email,
                  username: updated_user.username,
                  avatar_url: updated_user.avatar_url,
                  confirmed_at: updated_user.confirmed_at
                }

                conn
                |> put_status(:created)
                |> json(profile)

              {:error, changeset} ->
                # Clean up the uploaded file if database update fails
                Storage.delete(key)

                errors =
                  changeset.errors
                  |> Enum.reduce(%{}, fn {field, {message, _}}, acc ->
                    Map.put(acc, field, message)
                  end)

                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: errors})
            end

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Failed to store avatar file: #{inspect(reason)}"})
        end
      end
    end
  end

  def upload_avatar(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Avatar file is required"})
  end

  @doc """
  Delete the current user's avatar.

  DELETE /api/account/avatar
  """
  def delete_avatar(conn, _params) do
    user = conn.assigns.current_scope.user

    if user.avatar_url do
      # Extract key from URL and delete the file
      key = extract_key_from_url(user.avatar_url)
      if key, do: Storage.delete(key)

      # Update user to remove avatar URL
      case Accounts.update_user_avatar(user, %{avatar_url: nil}) do
        {:ok, updated_user} ->
          profile = %{
            id: updated_user.id,
            email: updated_user.email,
            username: updated_user.username,
            avatar_url: updated_user.avatar_url,
            confirmed_at: updated_user.confirmed_at
          }

          conn
          |> put_status(:ok)
          |> json(profile)

        {:error, changeset} ->
          errors =
            changeset.errors
            |> Enum.reduce(%{}, fn {field, {message, _}}, acc ->
              Map.put(acc, field, message)
            end)

          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: errors})
      end
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "No avatar to delete"})
    end
  end

  @doc """
  Request an email address change.

  Requires current password for security.

  POST /api/account/email/change-request
  """
  def request_email_change(conn, %{"new_email" => new_email, "password" => password}) do
    user = conn.assigns.current_scope.user

    # Verify current password
    if Accounts.get_user_by_email_and_password(user.email, password) do
      # Create changeset for email change
      case Accounts.change_user_email(user, %{email: new_email}) do
        %{valid?: true} = changeset ->
          # Apply the changeset to get the updated user for email delivery
          updated_user = Ecto.Changeset.apply_action!(changeset, :insert)

          # Generate URL function for the confirmation link
          url_fun = fn token ->
            # For API, we'll use a relative URL that the frontend can handle
            "/api/account/email/change-confirm?token=#{token}"
          end

          Accounts.deliver_user_update_email_instructions(
            updated_user,
            user.email,
            url_fun
          )

          conn
          |> put_status(:ok)
          |> json(%{message: "Email change instructions sent to #{new_email}"})

        changeset ->
          errors =
            changeset.errors
            |> Enum.reduce(%{}, fn {field, {message, _}}, acc ->
              Map.put(acc, field, message)
            end)

          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: errors})
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Invalid password"})
    end
  end

  @doc """
  Confirm an email address change using a token.

  POST /api/account/email/change-confirm
  """
  def confirm_email_change(conn, params) do
    # Token can come from either body params or query params
    token = params["token"] || conn.query_params["token"]

    if token do
      case Accounts.update_user_email(conn.assigns.current_scope.user, token) do
        {:ok, user} ->
          profile = %{
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatar_url,
            confirmed_at: user.confirmed_at
          }

          conn
          |> put_status(:ok)
          |> json(%{message: "Email updated successfully", profile: profile})

        {:error, _reason} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Invalid or expired token"})
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "Token is required"})
    end
  end

  # Helper function to extract storage key from URL
  # This is a simple implementation - adjust based on your Storage module's URL structure
  defp extract_key_from_url(url) do
    # Assuming URLs are in format: https://storage.example.com/avatars/user_id/filename
    # Extract everything after the domain
    case URI.parse(url) do
      %URI{path: path} when not is_nil(path) ->
        # Remove leading slash if present
        case path do
          "/" <> key -> key
          key -> key
        end
      _ ->
        nil
    end
  end
end
