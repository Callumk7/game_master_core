defmodule GameMasterCore.Storage do
  @moduledoc """
  Main storage interface that delegates to the configured storage adapter.

  This module provides a unified interface for file storage operations while
  allowing the underlying storage mechanism to be switched via configuration.
  """

  @doc """
  Store a file from the given file path using the configured storage adapter.

  ## Examples

      iex> GameMasterCore.Storage.store("/tmp/image.jpg", "uploads/image-123.jpg")
      {:ok, %{url: "/uploads/image-123.jpg", metadata: %{size: 12345}}}
      
      iex> GameMasterCore.Storage.store("/tmp/image.jpg", "uploads/image-123.jpg", content_type: "image/jpeg")
      {:ok, %{url: "/uploads/image-123.jpg", metadata: %{size: 12345}}}
  """
  @spec store(String.t(), String.t(), Keyword.t()) ::
          {:ok, %{url: String.t(), metadata: map()}} | {:error, term()}
  def store(file_path, key, opts \\ []) do
    adapter().store(file_path, key, opts)
  end

  @doc """
  Retrieve file content for the given key using the configured storage adapter.
  """
  @spec retrieve(String.t()) :: {:ok, binary()} | {:error, term()}
  def retrieve(key) do
    adapter().retrieve(key)
  end

  @doc """
  Delete the file with the given key using the configured storage adapter.
  """
  @spec delete(String.t()) :: :ok | {:error, term()}
  def delete(key) do
    adapter().delete(key)
  end

  @doc """
  Get the public URL for the file with the given key.
  """
  @spec get_url(String.t()) :: String.t()
  def get_url(key) do
    adapter().get_url(key)
  end

  @doc """
  Check if a file exists for the given key.
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(key) do
    adapter().exists?(key)
  end

  @doc """
  Get the currently configured storage adapter module.

  Defaults to the local filesystem adapter if no adapter is configured.
  """
  @spec adapter() :: module()
  def adapter do
    Application.get_env(:game_master_core, :storage_adapter, GameMasterCore.Storage.Local)
  end
end
