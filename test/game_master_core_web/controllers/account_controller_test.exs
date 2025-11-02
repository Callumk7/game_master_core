defmodule GameMasterCoreWeb.AccountControllerTest do
  use GameMasterCoreWeb.ConnCase

  alias GameMasterCore.Accounts
  alias GameMasterCore.AccountsFixtures

  setup %{conn: conn} do
    user = AccountsFixtures.user_fixture()
    user = AccountsFixtures.set_password(user)

    token = Accounts.generate_user_session_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{Base.url_encode64(token)}")
      |> put_req_header("accept", "application/json")

    %{conn: conn, user: user}
  end

  describe "GET /api/account/profile" do
    test "returns user profile", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/account/profile")

      response = json_response(conn, 200)

      assert %{
               "id" => user_id,
               "email" => email,
               "username" => username,
               "avatar_url" => avatar_url,
               "confirmed_at" => confirmed_at
             } = response

      assert user_id == user.id
      assert email == user.email
      assert username == user.username
      assert avatar_url == user.avatar_url
      assert confirmed_at != nil
    end

    test "requires authentication", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> get(~p"/api/account/profile")

      assert json_response(conn, 401)
    end
  end

  describe "PATCH /api/account/profile" do
    test "updates username when data is valid", %{conn: conn, user: user} do
      attrs = %{"username" => "new_username"}
      conn = patch(conn, ~p"/api/account/profile", attrs)

      response = json_response(conn, 200)

      assert %{
               "id" => user_id,
               "email" => email,
               "username" => username,
               "avatar_url" => avatar_url,
               "confirmed_at" => confirmed_at
             } = response

      assert user_id == user.id
      assert email == user.email
      assert username == "new_username"
      assert avatar_url == user.avatar_url
      assert confirmed_at != nil
    end

    test "returns errors when username is invalid", %{conn: conn} do
      # too short
      attrs = %{"username" => "ab"}
      conn = patch(conn, ~p"/api/account/profile", attrs)

      response = json_response(conn, 422)
      assert %{"errors" => %{"username" => _}} = response
    end

    test "requires authentication", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> patch(~p"/api/account/profile", %{"username" => "test"})

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/account/avatar" do
    test "uploads avatar when file is valid", %{conn: conn, user: user} do
      # Create a temporary image file
      {:ok, tmp_path} = create_temp_image("test.jpg", "image/jpeg")

      upload = %Plug.Upload{
        path: tmp_path,
        filename: "test.jpg",
        content_type: "image/jpeg"
      }

      conn = post(conn, ~p"/api/account/avatar", %{"avatar" => upload})

      response = json_response(conn, 201)

      assert %{
               "id" => user_id,
               "email" => email,
               "username" => username,
               "avatar_url" => avatar_url,
               "confirmed_at" => confirmed_at
             } = response

      assert user_id == user.id
      assert email == user.email
      assert username == user.username
      assert avatar_url != nil
      assert confirmed_at != nil

      # Clean up temp file
      File.rm(tmp_path)
    end

    test "returns error when file type is invalid", %{conn: conn} do
      {:ok, tmp_path} = create_temp_image("test.txt", "text/plain")

      upload = %Plug.Upload{
        path: tmp_path,
        filename: "test.txt",
        content_type: "text/plain"
      }

      conn = post(conn, ~p"/api/account/avatar", %{"avatar" => upload})

      response = json_response(conn, 422)

      assert %{"error" => "Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed."} =
               response

      File.rm(tmp_path)
    end

    test "returns error when file is too large", %{conn: conn} do
      # Create a file larger than 5MB
      {:ok, tmp_path} = create_temp_image("large.jpg", "image/jpeg", 6 * 1024 * 1024)

      upload = %Plug.Upload{
        path: tmp_path,
        filename: "large.jpg",
        content_type: "image/jpeg"
      }

      conn = post(conn, ~p"/api/account/avatar", %{"avatar" => upload})

      response = json_response(conn, 422)
      assert %{"error" => "File too large. Maximum size is 5MB."} = response

      File.rm(tmp_path)
    end

    test "requires authentication", %{conn: conn} do
      {:ok, tmp_path} = create_temp_image("test.jpg", "image/jpeg")

      upload = %Plug.Upload{
        path: tmp_path,
        filename: "test.jpg",
        content_type: "image/jpeg"
      }

      conn =
        conn
        |> delete_req_header("authorization")
        |> post(~p"/api/account/avatar", %{"avatar" => upload})

      assert json_response(conn, 401)

      File.rm(tmp_path)
    end
  end

  describe "DELETE /api/account/avatar" do
    test "deletes avatar when user has one", %{conn: conn, user: user} do
      # First upload an avatar
      {:ok, tmp_path} = create_temp_image("test.jpg", "image/jpeg")

      upload = %Plug.Upload{
        path: tmp_path,
        filename: "test.jpg",
        content_type: "image/jpeg"
      }

      post(conn, ~p"/api/account/avatar", %{"avatar" => upload})

      # Now delete it
      conn = delete(conn, ~p"/api/account/avatar")

      response = json_response(conn, 200)

      assert %{
               "id" => user_id,
               "email" => email,
               "username" => username,
               "avatar_url" => avatar_url,
               "confirmed_at" => confirmed_at
             } = response

      assert user_id == user.id
      assert email == user.email
      assert username == user.username
      assert avatar_url == nil
      assert confirmed_at != nil

      File.rm(tmp_path)
    end

    test "returns error when user has no avatar", %{conn: conn} do
      conn = delete(conn, ~p"/api/account/avatar")

      response = json_response(conn, 404)
      assert %{"error" => "No avatar to delete"} = response
    end

    test "requires authentication", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> delete(~p"/api/account/avatar")

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/account/email/change-request" do
    test "sends email change request when data is valid", %{conn: conn, user: _user} do
      attrs = %{
        "new_email" => "new#{System.unique_integer()}@example.com",
        "password" => AccountsFixtures.valid_user_password()
      }

      conn = post(conn, ~p"/api/account/email/change-request", attrs)

      response = json_response(conn, 200)
      assert %{"message" => message} = response
      assert String.contains?(message, attrs["new_email"])
    end

    test "returns error when password is invalid", %{conn: conn} do
      attrs = %{
        "new_email" => "new@example.com",
        "password" => "wrong_password"
      }

      conn = post(conn, ~p"/api/account/email/change-request", attrs)

      response = json_response(conn, 401)
      assert %{"error" => "Invalid password"} = response
    end

    test "returns validation errors for invalid email", %{conn: conn} do
      attrs = %{
        "new_email" => "invalid-email",
        "password" => AccountsFixtures.valid_user_password()
      }

      conn = post(conn, ~p"/api/account/email/change-request", attrs)

      response = json_response(conn, 422)
      assert %{"errors" => %{"email" => _}} = response
    end

    test "requires authentication", %{conn: conn} do
      attrs = %{
        "new_email" => "new@example.com",
        "password" => AccountsFixtures.valid_user_password()
      }

      conn =
        conn
        |> delete_req_header("authorization")
        |> post(~p"/api/account/email/change-request", attrs)

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/account/email/change-confirm" do
    test "returns error with invalid token", %{conn: conn} do
      conn = post(conn, ~p"/api/account/email/change-confirm", %{"token" => "invalid"})

      response = json_response(conn, 422)
      assert %{"error" => "Invalid or expired token"} = response
    end

    test "requires token parameter", %{conn: conn} do
      conn = post(conn, ~p"/api/account/email/change-confirm", %{})

      response = json_response(conn, 422)
      assert %{"error" => "Token is required"} = response
    end

    test "requires authentication", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> post(~p"/api/account/email/change-confirm", %{"token" => "sometoken"})

      assert json_response(conn, 401)
    end
  end

  # Helper functions

  defp create_temp_image(_filename, _content_type, size_bytes \\ 1024) do
    tmp_path = Path.join(System.tmp_dir!(), "test_upload_#{System.unique_integer()}.jpg")
    content = :crypto.strong_rand_bytes(size_bytes)
    File.write!(tmp_path, content)
    {:ok, tmp_path}
  end
end
