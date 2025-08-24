defmodule GameMasterCoreWeb.TokenController do
  use GameMasterCoreWeb, :controller

  alias GameMasterCore.Accounts

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})

      user ->
        token = Accounts.create_user_api_token(user)

        conn
        |> put_status(:created)
        |> json(%{token: token})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Invalid request"})
  end
end
