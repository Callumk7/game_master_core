defmodule GameMasterCoreWeb.SearchController do
  use GameMasterCoreWeb, :controller
  use PhoenixSwagger

  alias GameMasterCore.Search
  alias GameMasterCoreWeb.SwaggerDefinitions

  def swagger_definitions do
    SwaggerDefinitions.common_definitions()
  end

  use GameMasterCoreWeb.Swagger.SearchSwagger

  action_fallback GameMasterCoreWeb.FallbackController

  def search(conn, params) do
    query = Map.get(params, "q")

    # Validate query parameter
    if is_nil(query) or String.trim(query) == "" do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Query parameter 'q' is required and cannot be empty"})
    else
      # Parse query parameters
      entity_types = parse_entity_types(params["types"])
      tags = parse_tags(params["tags"])
      pinned_only = parse_boolean(params["pinned_only"], false)
      limit = parse_integer(params["limit"], 50)
      offset = parse_integer(params["offset"], 0)

      # Perform search
      results =
        Search.search_game(
          conn.assigns.current_scope,
          query,
          entity_types: entity_types,
          tags: tags,
          pinned_only: pinned_only,
          limit: limit,
          offset: offset
        )

      render(conn, :search, results: results)
    end
  end

  # Parse comma-separated entity types
  defp parse_entity_types(nil), do: nil
  defp parse_entity_types(""), do: nil

  defp parse_entity_types(types) when is_binary(types) do
    types
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  # Parse comma-separated tags
  defp parse_tags(nil), do: nil
  defp parse_tags(""), do: nil

  defp parse_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      parsed_tags -> parsed_tags
    end
  end

  # Parse boolean values
  defp parse_boolean(nil, default), do: default
  defp parse_boolean("", default), do: default
  defp parse_boolean("true", _default), do: true
  defp parse_boolean("false", _default), do: false
  defp parse_boolean(true, _default), do: true
  defp parse_boolean(false, _default), do: false
  defp parse_boolean(_, default), do: default

  # Parse integer values with default
  defp parse_integer(nil, default), do: default
  defp parse_integer("", default), do: default

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp parse_integer(_, default), do: default
end
