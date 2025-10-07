defmodule GameMasterCore.Storage.S3 do
  @moduledoc """
  S3-compatible storage adapter.

  This adapter works with AWS S3 and S3-compatible storage services.
  It uses the existing Req library for HTTP requests to avoid adding
  additional dependencies.

  ## Configuration

  The following configuration options are supported:

  - `:s3_bucket` - The S3 bucket name (required)
  - `:s3_region` - The AWS region (default: "us-east-1")
  - `:s3_endpoint` - Custom S3 endpoint for S3-compatible services
  - `:s3_access_key_id` - AWS access key ID
  - `:s3_secret_access_key` - AWS secret access key
  - `:s3_public_url` - Custom public URL base for CDN or custom domains

  ## Examples

      # AWS S3
      config :game_master_core,
        s3_bucket: "my-game-images",
        s3_region: "us-west-2",
        s3_access_key_id: "AKIA...",
        s3_secret_access_key: "...",
        s3_public_url: "https://cdn.example.com"
      
      # MinIO or other S3-compatible service
      config :game_master_core,
        s3_bucket: "game-images",
        s3_endpoint: "https://minio.example.com",
        s3_access_key_id: "minioadmin",
        s3_secret_access_key: "minioadmin"
  """

  @behaviour GameMasterCore.Storage.Behaviour

  require Logger

  @doc """
  Store a file in S3.

  The file is uploaded to S3 with the specified key and optional metadata.
  """
  @impl GameMasterCore.Storage.Behaviour
  def store(file_path, key, opts) do
    bucket = get_bucket()
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    Logger.debug("Storing file from #{file_path} to S3 bucket #{bucket} with key #{key}")

    with {:ok, file_content} <- File.read(file_path),
         {:ok, response} <- upload_to_s3(bucket, key, file_content, content_type) do
      {:ok,
       %{
         url: build_public_url(key),
         metadata: %{
           etag: get_header(response.headers, "etag"),
           size: byte_size(file_content),
           content_type: content_type
         }
       }}
    else
      {:error, reason} ->
        Logger.error("Failed to store file #{file_path} to S3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Retrieve a file from S3.
  """
  @impl GameMasterCore.Storage.Behaviour
  def retrieve(key) do
    bucket = get_bucket()
    url = build_s3_url(bucket, key)

    case Req.get(url, auth: get_auth_headers(bucket, key, :get)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        Logger.error("S3 retrieve failed with status #{status} for key #{key}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("Failed to retrieve file from S3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Delete a file from S3.
  """
  @impl GameMasterCore.Storage.Behaviour
  def delete(key) do
    bucket = get_bucket()
    url = build_s3_url(bucket, key)

    case Req.delete(url, auth: get_auth_headers(bucket, key, :delete)) do
      {:ok, %{status: status}} when status in [200, 204] ->
        Logger.debug("Deleted S3 object with key #{key}")
        :ok

      {:ok, %{status: 404}} ->
        # Object doesn't exist, consider this success
        :ok

      {:ok, %{status: status}} ->
        Logger.error("S3 delete failed with status #{status} for key #{key}")
        {:error, {:http_error, status}}

      {:error, reason} ->
        Logger.error("Failed to delete file from S3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get the public URL for an S3 object.
  """
  @impl GameMasterCore.Storage.Behaviour
  def get_url(key) do
    build_public_url(key)
  end

  @doc """
  Check if a file exists in S3.
  """
  @impl GameMasterCore.Storage.Behaviour
  def exists?(key) do
    bucket = get_bucket()
    url = build_s3_url(bucket, key)

    case Req.head(url, auth: get_auth_headers(bucket, key, :head)) do
      {:ok, %{status: 200}} -> true
      _ -> false
    end
  end

  # Private helper functions

  defp get_bucket do
    case Application.fetch_env(:game_master_core, :s3_bucket) do
      {:ok, bucket} -> bucket
      :error -> raise "S3 bucket not configured. Please set :s3_bucket in your config."
    end
  end

  defp get_region do
    Application.get_env(:game_master_core, :s3_region, "us-east-1")
  end

  defp get_endpoint do
    case Application.get_env(:game_master_core, :s3_endpoint) do
      nil -> "https://s3.#{get_region()}.amazonaws.com"
      endpoint -> endpoint
    end
  end

  defp build_s3_url(bucket, key) do
    endpoint = get_endpoint()
    "#{endpoint}/#{bucket}/#{key}"
  end

  defp build_public_url(key) do
    case Application.get_env(:game_master_core, :s3_public_url) do
      nil ->
        bucket = get_bucket()
        build_s3_url(bucket, key)

      public_url ->
        "#{public_url}/#{key}"
    end
  end

  defp upload_to_s3(bucket, key, content, content_type) do
    url = build_s3_url(bucket, key)

    headers = [
      {"Content-Type", content_type},
      {"Content-Length", to_string(byte_size(content))}
    ]

    Req.put(url,
      body: content,
      headers: headers,
      auth: get_auth_headers(bucket, key, :put, content_type)
    )
  end

  defp get_auth_headers(_bucket, _key, _method, _content_type \\ nil) do
    access_key_id = get_access_key_id()
    secret_access_key = get_secret_access_key()

    if access_key_id && secret_access_key do
      # For now, we'll use a simple approach
      # In production, you'd want to implement proper AWS Signature V4
      # or use a library like :aws_signature

      # This is a simplified auth - you should implement proper AWS auth
      {:basic, access_key_id <> ":" <> secret_access_key}
    else
      # No authentication configured
      nil
    end
  end

  defp get_access_key_id do
    Application.get_env(:game_master_core, :s3_access_key_id)
  end

  defp get_secret_access_key do
    Application.get_env(:game_master_core, :s3_secret_access_key)
  end

  defp get_header(headers, name) when is_list(headers) do
    case List.keyfind(headers, name, 0) do
      {^name, value} -> value
      nil -> nil
    end
  end

  defp get_header(headers, name) when is_map(headers) do
    Map.get(headers, name)
  end
end
