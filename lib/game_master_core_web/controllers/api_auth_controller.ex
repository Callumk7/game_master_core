defmodule GameMasterCoreWeb.ApiAuthController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Accounts
  alias GameMasterCoreWeb.UserAuth
  alias GameMasterCoreWeb.SwaggerDefinitions
  alias PhoenixSwagger.Schema

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  swagger_path :signup do
    post("/api/auth/signup")
    summary("Sign up new user")
    description("Register a new user with email and password")
    operation_id("signupUser")
    tag("Authentication")
    consumes("application/json")
    produces("application/json")

    parameters do
      body(:body, Schema.ref(:SignupRequest), "Signup credentials", required: true)
    end

    response(201, "Created", Schema.ref(:LoginResponse))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
  end

  swagger_path :login do
    post("/api/auth/login")
    summary("Login user")
    description("Authenticate user with email/password or magic link token")
    operation_id("loginUser")
    tag("Authentication")
    consumes("application/json")
    produces("application/json")

    parameters do
      body(:body, Schema.ref(:LoginRequest), "Login credentials", required: true)
    end

    response(200, "Success", Schema.ref(:LoginResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

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
            confirmed_at: user.confirmed_at
          }
        })

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired magic link"})
    end
  end

  swagger_path :logout do
    PhoenixSwagger.Path.delete("/api/auth/logout")
    summary("Logout user")
    description("Invalidate current session token")
    operation_id("logoutUser")
    tag("Authentication")

    security([%{Bearer: []}])

    response(200, "Success")
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  def logout(conn, _params) do
    if token = get_req_header(conn, "authorization") |> extract_session_token() do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> put_status(:ok)
    |> json(%{message: "Logged out successfully"})
  end

  swagger_path :status do
    get("/api/auth/status")
    summary("Get auth status")
    description("Check if user is authenticated and get user info")
    operation_id("getAuthStatus")
    tag("Authentication")
    produces("application/json")

    security([%{Bearer: []}])

    response(200, "Success", Schema.ref(:AuthStatusResponse))
    response(401, "Unauthorized", Schema.ref(:Error))
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
