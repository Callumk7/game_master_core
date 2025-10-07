defmodule GameMasterCore.Storage.Local do
  @moduledoc """
  Local filesystem storage adapter.

  This adapter stores files on the local filesystem and serves them
  via the Phoenix application. Suitable for development and single-server
  deployments.
  """

  @behaviour GameMasterCore.Storage.Behaviour

  require Logger

  @doc """
  Store a file on the local filesystem.

  Files are stored in the configured uploads directory with the full key path.
  The directory structure is created automatically if it doesn't exist.
  """
  @impl GameMasterCore.Storage.Behaviour
  def store(file_path, key, _opts) do
    upload_dir = get_upload_directory()
    dest_path = Path.join(upload_dir, key)

    Logger.debug("Storing file from #{file_path} to #{dest_path}")

    with :ok <- ensure_directory_exists(dest_path),
         {:ok, _bytes} <- File.copy(file_path, dest_path) do
      file_stat = File.stat!(dest_path)

      # Convert Erlang datetime tuple to ISO8601 string for JSON compatibility
      modified_at =
        file_stat.mtime
        |> NaiveDateTime.from_erl!()
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_iso8601()

      {:ok,
       %{
         url: build_public_url(key),
         metadata: %{
           path: dest_path,
           size: file_stat.size,
           modified_at: modified_at
         }
       }}
    else
      {:error, reason} ->
        Logger.error("Failed to store file #{file_path} to #{dest_path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Retrieve a file from the local filesystem.
  """
  @impl GameMasterCore.Storage.Behaviour
  def retrieve(key) do
    upload_dir = get_upload_directory()
    file_path = Path.join(upload_dir, key)

    case File.read(file_path) do
      {:ok, content} ->
        {:ok, content}

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to retrieve file #{file_path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Delete a file from the local filesystem.
  """
  @impl GameMasterCore.Storage.Behaviour
  def delete(key) do
    upload_dir = get_upload_directory()
    file_path = Path.join(upload_dir, key)

    case File.rm(file_path) do
      :ok ->
        Logger.debug("Deleted file #{file_path}")
        # Try to clean up empty directories
        cleanup_empty_directories(Path.dirname(file_path), upload_dir)
        :ok

      {:error, :enoent} ->
        # File doesn't exist, consider this success
        :ok

      {:error, reason} ->
        Logger.error("Failed to delete file #{file_path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get the public URL for a file.

  Returns a URL that can be used to access the file via the web server.
  """
  @impl GameMasterCore.Storage.Behaviour
  def get_url(key) do
    build_public_url(key)
  end

  @doc """
  Check if a file exists on the local filesystem.
  """
  @impl GameMasterCore.Storage.Behaviour
  def exists?(key) do
    upload_dir = get_upload_directory()
    file_path = Path.join(upload_dir, key)
    File.exists?(file_path)
  end

  # Private helper functions

  defp get_upload_directory do
    upload_dir = Application.get_env(:game_master_core, :uploads_directory, "uploads")

    # Ensure the base upload directory exists
    case File.mkdir_p(upload_dir) do
      :ok ->
        upload_dir

      {:error, reason} ->
        Logger.error("Failed to create uploads directory #{upload_dir}: #{inspect(reason)}")
        upload_dir
    end
  end

  defp build_public_url(key) do
    base_url = Application.get_env(:game_master_core, :uploads_base_url, "/uploads")
    "#{base_url}/#{key}"
  end

  defp ensure_directory_exists(file_path) do
    dir_path = Path.dirname(file_path)

    case File.mkdir_p(dir_path) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp cleanup_empty_directories(dir_path, root_dir) do
    # Don't try to clean up the root uploads directory or above
    if String.starts_with?(dir_path, root_dir) and dir_path != root_dir do
      case File.ls(dir_path) do
        {:ok, []} ->
          # Directory is empty, try to remove it
          case File.rmdir(dir_path) do
            :ok ->
              # Try to clean up parent directory too
              cleanup_empty_directories(Path.dirname(dir_path), root_dir)

            {:error, _reason} ->
              # Failed to remove directory, stop here
              :ok
          end

        _ ->
          # Directory is not empty or we can't read it, stop here
          :ok
      end
    end
  end
end
