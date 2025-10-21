defmodule GameMasterCoreWeb.ApiAuthController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Accounts
  alias GameMasterCoreWeb.UserAuth
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.ApiAuthSwagger

  def signup(conn, %{"email" => email, "password" => password}) do
    case Accounts.register_user_api(%{"email" => email, "password" => password}) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_status(:created)
        |> json(%{
          token: Base.url_encode64(token),
          user: %{
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatar_url,
            confirmed_at: user.confirmed_at
          }
        })

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

  def login(conn, %{"email" => email, "password" => password}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)

      conn
      |> put_status(:ok)
      |> json(%{
        token: Base.url_encode64(token),
        user: %{
          id: user.id,
          email: user.email,
          username: user.username,
          avatar_url: user.avatar_url,
          confirmed_at: user.confirmed_at
        }
      })
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Invalid email or password"})
    end
  end

  def login(conn, %{"token" => magic_token}) do
    case Accounts.login_user_by_magic_link(magic_token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_status(:ok)
        |> json(%{
          token: Base.url_encode64(token),
          user: %{
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatar_url,
            confirmed_at: user.confirmed_at
          }
        })

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired magic link"})
    end
  end

  def logout(conn, _params) do
    if token = get_req_header(conn, "authorization") |> extract_session_token() do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> put_status(:ok)
    |> json(%{message: "Logged out successfully"})
  end

  def status(conn, _params) do
    current_scope = conn.assigns.current_scope

    if current_scope && current_scope.user do
      conn
      |> put_status(:ok)
      |> json(%{
        authenticated: true,
        user: %{
          id: current_scope.user.id,
          email: current_scope.user.email,
          username: current_scope.user.username,
          avatar_url: current_scope.user.avatar_url,
          confirmed_at: current_scope.user.confirmed_at
        }
      })
    else
      conn
      |> put_status(:ok)
      |> json(%{authenticated: false})
    end
  end

  defp extract_session_token([]), do: nil

  defp extract_session_token([auth_header]) do
    case String.split(auth_header, " ", parts: 2) do
      ["Bearer", encoded_token] ->
        case Base.url_decode64(encoded_token) do
          {:ok, token} -> token
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp extract_session_token(_), do: nil
end
