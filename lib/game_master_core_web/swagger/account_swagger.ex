defmodule GameMasterCoreWeb.Swagger.AccountSwagger do
  @moduledoc """
  Swagger documentation definitions for AccountController
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger
      alias PhoenixSwagger.Schema

      swagger_path :show do
        get("/api/account/profile")
        summary("Get user profile")
        description("Retrieve the current user's profile information")
        operation_id("getUserProfile")
        tag("Account")
        produces("application/json")

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:User))
        response(401, "Unauthorized", Schema.ref(:Error))
      end

      swagger_path :update do
        patch("/api/account/profile")
        summary("Update user profile")

        description(
          "Update the current user's profile information (currently supports username updates)"
        )

        operation_id("updateUserProfile")
        tag("Account")
        consumes("application/json")
        produces("application/json")

        security([%{Bearer: []}])

        parameters do
          body(:body, Schema.ref(:ProfileUpdate), "Profile update data", required: true)
        end

        response(200, "Success", Schema.ref(:User))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(422, "Validation error", Schema.ref(:Error))
      end

      swagger_path :upload_avatar do
        post("/api/account/avatar")
        summary("Upload user avatar")

        description(
          "Upload a new avatar image for the current user. Supports JPEG, PNG, GIF, and WebP formats up to 5MB."
        )

        operation_id("uploadUserAvatar")
        tag("Account")
        consumes("multipart/form-data")
        produces("application/json")

        security([%{Bearer: []}])

        parameter("avatar", :formData, :file, "Avatar image file", required: true)

        response(201, "Created", Schema.ref(:User))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(422, "Validation error", Schema.ref(:Error))
      end

      swagger_path :delete_avatar do
        PhoenixSwagger.Path.delete("/api/account/avatar")
        summary("Delete user avatar")
        description("Remove the current user's avatar image")
        operation_id("deleteUserAvatar")
        tag("Account")
        produces("application/json")

        security([%{Bearer: []}])

        response(200, "Success", Schema.ref(:User))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(404, "Not found", Schema.ref(:Error))
      end

      swagger_path :request_email_change do
        post("/api/account/email/change-request")
        summary("Request email change")

        description(
          "Request to change the user's email address. Requires current password verification and sends confirmation to new email."
        )

        operation_id("requestEmailChange")
        tag("Account")
        consumes("application/json")
        produces("application/json")

        security([%{Bearer: []}])

        parameters do
          body(:body, Schema.ref(:EmailChangeRequest), "Email change request data",
            required: true
          )
        end

        response(200, "Success", Schema.ref(:SuccessResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(422, "Validation error", Schema.ref(:Error))
      end

      swagger_path :confirm_email_change do
        post("/api/account/email/change-confirm")
        summary("Confirm email change")

        description(
          "Confirm an email address change using the token sent to the new email address"
        )

        operation_id("confirmEmailChange")
        tag("Account")
        consumes("application/json")
        produces("application/json")

        security([%{Bearer: []}])

        parameters do
          body(:body, Schema.ref(:EmailChangeConfirm), "Email change confirmation data",
            required: true
          )
        end

        response(200, "Success", Schema.ref(:SuccessResponse))
        response(401, "Unauthorized", Schema.ref(:Error))
        response(422, "Invalid token", Schema.ref(:Error))
      end
    end
  end
end
