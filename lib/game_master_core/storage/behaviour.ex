defmodule GameMasterCore.Storage.Behaviour do
  @moduledoc """
  Behaviour defining the contract for storage adapters.

  This allows for pluggable storage backends (local filesystem, S3, etc.)
  while maintaining a consistent interface throughout the application.
  """

  @doc """
  Store a file from the given file path to the storage backend with the specified key.

  ## Parameters
  - file_path: Path to the file to be stored
  - key: Unique identifier/path for the stored file
  - opts: Additional options like content_type, metadata, etc.

  ## Returns
  - {:ok, %{url: String.t(), metadata: map()}} on success
  - {:error, term()} on failure
  """
  @callback store(file_path :: String.t(), key :: String.t(), opts :: Keyword.t()) ::
              {:ok, %{url: String.t(), metadata: map()}} | {:error, term()}

  @doc """
  Retrieve the raw file content for the given key.

  ## Parameters
  - key: The unique identifier for the file

  ## Returns
  - {:ok, binary()} on success
  - {:error, term()} on failure
  """
  @callback retrieve(key :: String.t()) :: {:ok, binary()} | {:error, term()}

  @doc """
  Delete the file associated with the given key.

  ## Parameters
  - key: The unique identifier for the file to delete

  ## Returns
  - :ok on success
  - {:error, term()} on failure
  """
  @callback delete(key :: String.t()) :: :ok | {:error, term()}

  @doc """
  Get the public URL for the file with the given key.

  ## Parameters
  - key: The unique identifier for the file

  ## Returns
  - String representing the public URL
  """
  @callback get_url(key :: String.t()) :: String.t()

  @doc """
  Check if a file exists for the given key.

  ## Parameters
  - key: The unique identifier for the file

  ## Returns
  - true if the file exists, false otherwise
  """
  @callback exists?(key :: String.t()) :: boolean()
end
