defmodule GameMasterCoreWeb.Controllers.LinkHelpers do
  @moduledoc """
  Shared helpers for entity linking functionality across controllers.
  """

  @doc """
  Validates entity type parameter for link operations.
  """
  def validate_entity_type(nil), do: {:error, :missing_entity_type}
  def validate_entity_type("note"), do: {:ok, :note}
  def validate_entity_type("character"), do: {:ok, :character}
  def validate_entity_type("faction"), do: {:ok, :faction}
  def validate_entity_type("item"), do: {:ok, :item}
  def validate_entity_type("location"), do: {:ok, :location}
  def validate_entity_type("quest"), do: {:ok, :quest}
  def validate_entity_type(_), do: {:error, :invalid_entity_type}

  @doc """
  Validates entity ID parameter for link operations.
  """
  def validate_entity_id(nil), do: {:error, :missing_entity_id}

  def validate_entity_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {integer_id, ""} -> {:ok, integer_id}
      _ -> {:error, :invalid_entity_id}
    end
  end

  def validate_entity_id(id) when is_integer(id), do: {:ok, id}
  def validate_entity_id(_), do: {:error, :invalid_entity_id}
end
