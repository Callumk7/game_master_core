defmodule GameMasterCoreWeb.ApiAuthControllerTest do
  use GameMasterCoreWeb.ConnCase

  alias GameMasterCore.Accounts

  @valid_signup_attrs %{
    "email" => "test@example.com",
    "password" => "password123456"
  }

  @invalid_signup_attrs %{
    "email" => "",
    "password" => ""
  }

  describe "POST /api/auth/signup" do
    test "creates user and returns token when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/signup", @valid_signup_attrs)

      response = json_response(conn, 201)
      assert %{"token" => token, "user" => user} = response
      assert is_binary(token)

      assert %{
               "id" => _id,
               "email" => "test@example.com",
               "username" => nil,
               "avatar_url" => nil,
               "confirmed_at" => nil
             } = user
    end

    test "returns errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/signup", @invalid_signup_attrs)

      response = json_response(conn, 422)
      assert %{"errors" => errors} = response
      assert errors != %{}
    end

    test "returns errors when email already exists", %{conn: conn} do
      # Create a user first
      {:ok, _user} = Accounts.register_user_api(@valid_signup_attrs)

      # Try to create another user with same email
      conn = post(conn, ~p"/api/auth/signup", @valid_signup_attrs)

      response = json_response(conn, 422)
      assert %{"errors" => errors} = response
      assert errors != %{}
    end
  end

  describe "POST /api/auth/login" do
    setup do
      {:ok, user} = Accounts.register_user_api(@valid_signup_attrs)
      %{user: user}
    end

    test "returns token when credentials are valid", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", @valid_signup_attrs)

      response = json_response(conn, 200)
      assert %{"token" => token, "user" => user} = response
      assert is_binary(token)

      assert %{
               "id" => _id,
               "email" => "test@example.com",
               "username" => nil,
               "avatar_url" => nil
             } = user
    end

    test "returns error when credentials are invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/login", %{
          "email" => "test@example.com",
          "password" => "wrongpassword"
        })

      response = json_response(conn, 401)
      assert %{"error" => _error} = response
    end
  end

  describe "GET /api/auth/status" do
    setup do
      {:ok, user} = Accounts.register_user_api(@valid_signup_attrs)
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: Base.url_encode64(token)}
    end

    test "returns user when authenticated", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/auth/status")

      response = json_response(conn, 200)

      assert %{
               "authenticated" => true,
               "user" => %{
                 "id" => _id,
                 "email" => "test@example.com",
                 "username" => nil,
                 "avatar_url" => nil
               }
             } = response
    end

    test "returns error when no token provided", %{conn: conn} do
      conn = get(conn, ~p"/api/auth/status")

      # /api/auth/status requires authentication
      response = json_response(conn, 401)
      assert %{"error" => _error} = response
    end
  end
end
