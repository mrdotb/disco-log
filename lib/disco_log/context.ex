defmodule DiscoLog.Context do
  @moduledoc """
  Context is a map of any terms that DiscoLog attaches to reported occurrences.
  The context is stored in `Logger` module metadata.

  > #### Using context {: .tip}
  >
  > `DiscoLog.Context` is mostly used by DiscoLog itself, but you might find it
  > useful if you want to add metadata to occurrences and not normal log
  > messages. Context is always exported, regardless of the `:metadata` configuration
  > option.
  """

  @type t() :: map()

  @logger_metadata_key :__disco_log__

  def __logger_metadata_key__ do
    @logger_metadata_key
  end

  @doc """
  Set context for the current process.
  """
  def set(key, value) do
    disco_log_metadata =
      case :logger.get_process_metadata() do
        %{@logger_metadata_key => context} -> Map.put(context, key, value)
        _ -> %{key => value}
      end

    :logger.update_process_metadata(%{@logger_metadata_key => disco_log_metadata})
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
