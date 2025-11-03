defmodule GameMasterCoreWeb.SwaggerHelper do
  @moduledoc """
  Helper macros and functions to reduce Swagger boilerplate in controllers.
  """

  import PhoenixSwagger
  alias PhoenixSwagger.Schema

  @doc """
  Common parameters used across endpoints
  """
  def common_parameters do
    %{
      id: {:path, :string, "ID", required: true, format: :uuid},
      game_id: {:path, :string, "Game ID", required: true, format: :uuid},
      user_id: {:path, :string, "User ID", required: true, format: :uuid}
    }
  end

  @doc """
  Common response codes and their schemas
  """
  def common_responses do
    %{
      200 => {"Success", nil},
      201 => {"Created", nil},
      204 => {"No Content", nil},
      400 => {"Bad Request", Schema.ref(:Error)},
      401 => {"Unauthorized", Schema.ref(:Error)},
      403 => {"Forbidden", Schema.ref(:Error)},
      404 => {"Not Found", Schema.ref(:Error)},
      422 => {"Unprocessable Entity", Schema.ref(:ValidationError)}
    }
  end

  @doc """
  Add standard parameters to a swagger_path
  """
  defmacro add_parameters(param_keys) when is_list(param_keys) do
    quote do
      parameters do
        (unquote_splicing(
           Enum.map(param_keys, fn key ->
             case GameMasterCoreWeb.SwaggerHelper.common_parameters()[key] do
               {location, type, desc, opts} ->
                 quote do:
                         unquote(key)(
                           unquote(location),
                           unquote(type),
                           unquote(desc),
                           unquote(opts)
                         )

               {location, type, desc} ->
                 quote do: unquote(key)(unquote(location), unquote(type), unquote(desc))
             end
           end)
         ))
      end
    end
  end

  @doc """
  Add standard responses to a swagger_path
  """
  defmacro add_responses(response_codes) when is_list(response_codes) do
    quote do
      (unquote_splicing(
         Enum.map(response_codes, fn code ->
           {description, schema} = GameMasterCoreWeb.SwaggerHelper.common_responses()[code]

           if schema do
             quote do: response(unquote(code), unquote(description), unquote(schema))
           else
             quote do: response(unquote(code), unquote(description))
           end
         end)
       ))
    end
  end

  @doc """
  Standard CRUD operation macro for resources
  """
  defmacro resource_operations(resource_name, opts \\ []) do
    entity_name = Keyword.get(opts, :entity, resource_name)
    tag_name = Keyword.get(opts, :tag, String.capitalize("#{resource_name}"))

    quote do
      swagger_path :index do
        get("/api/#{unquote(resource_name)}")
        summary("List all #{unquote(resource_name)}")

        description(
          "Retrieve a list of all #{unquote(resource_name)} accessible to the current user"
        )

        tag(unquote(tag_name))
        produces("application/json")
        add_parameters([])

        response(
          200,
          "Success",
          Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Response"))
        )

        add_responses([401])
      end

      swagger_path :create do
        post("/api/#{unquote(resource_name)}")
        summary("Create a new #{String.slice(unquote(resource_name), 0..-2//-1)}")

        description(
          "Create a new #{String.slice(unquote(resource_name), 0..-2//-1)} with the provided parameters"
        )

        tag(unquote(tag_name))
        consumes("application/json")
        produces("application/json")
        add_parameters([])

        parameters do
          body(
            :body,
            Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Request")),
            "#{String.capitalize(unquote(entity_name))} parameters",
            required: true
          )
        end

        response(
          201,
          "Created",
          Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Response"))
        )

        add_responses([400, 401, 422])
      end

      swagger_path :show do
        get("/api/#{unquote(resource_name)}/{id}")
        summary("Get a #{String.slice(unquote(resource_name), 0..-2//-1)}")

        description(
          "Retrieve a specific #{String.slice(unquote(resource_name), 0..-2//-1)} by its ID"
        )

        tag(unquote(tag_name))
        produces("application/json")
        add_parameters([:id])

        response(
          200,
          "Success",
          Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Response"))
        )

        add_responses([401, 404])
      end

      swagger_path :update do
        put("/api/#{unquote(resource_name)}/{id}")
        summary("Update a #{String.slice(unquote(resource_name), 0..-2//-1)}")

        description(
          "Update a specific #{String.slice(unquote(resource_name), 0..-2//-1)} with the provided parameters"
        )

        tag(unquote(tag_name))
        consumes("application/json")
        produces("application/json")
        add_parameters([:id])

        parameters do
          body(
            :body,
            Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Request")),
            "#{String.capitalize(unquote(entity_name))} parameters",
            required: true
          )
        end

        response(
          200,
          "Success",
          Schema.ref(String.to_atom("#{String.capitalize(unquote(entity_name))}Response"))
        )

        add_responses([400, 401, 404, 422])
      end

      swagger_path :delete do
        PhoenixSwagger.Path.delete("/api/#{unquote(resource_name)}/{id}")
        summary("Delete a #{String.slice(unquote(resource_name), 0..-2//-1)}")

        description(
          "Delete a specific #{String.slice(unquote(resource_name), 0..-2//-1)} by its ID"
        )

        tag(unquote(tag_name))
        add_parameters([:id])
        add_responses([204, 401, 404])
      end
    end
  end
end
