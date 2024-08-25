defmodule DiscoLog.Context do
  @moduledoc """
  Add context to logs and errors using the Logger metadata.
  """

  @logger_metadata_key :__disco_log__

  def __logger_metadata_key__ do
    @logger_metadata_key
  end

  def set(key, new) when is_map(new) do
    sentry_metadata =
      case :logger.get_process_metadata() do
        %{@logger_metadata_key => config} -> Map.update(config, key, new, &Map.merge(&1, new))
        _ -> %{key => new}
      end

    :logger.update_process_metadata(%{@logger_metadata_key => sentry_metadata})
  end

  @doc """
  Obtain the context of the current process.
  """
  def get do
    case :logger.get_process_metadata() do
      %{@logger_metadata_key => config} -> config
      %{} -> %{}
      :undefined -> %{}
    end
  end
end
