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
      assert %{"id" => _id, "email" => "test@example.com"} = user
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
end
