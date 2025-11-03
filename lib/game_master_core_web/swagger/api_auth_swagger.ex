defmodule GameMasterCoreWeb.Swagger.ApiAuthSwagger do
  @moduledoc """
  Swagger documentation definitions for ApiAuthController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

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
        response(422, "Unprocessable Entity", Schema.ref(:ValidationError))
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
    end
  end
end
