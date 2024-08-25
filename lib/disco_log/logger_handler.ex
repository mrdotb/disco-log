defmodule DiscoLog.LoggerHandler do
  @moduledoc """
  A logger handler [`:logger` handler](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#handlers)

  Original source: https://github.com/getsentry/sentry-elixir/blob/69ac8d0e3f33ff36ab1092bbd346fdb99cf9d061/lib/sentry/logger_handler.ex
  """

  alias __MODULE__
  alias DiscoLog.Client
  alias DiscoLog.Config
  alias DiscoLog.Context
  alias DiscoLog.Error

  defstruct excluded_domains: [:cowboy, :bandit],
            metadata: [],
            info_channel_id: nil,
            error_channel_id: nil

  ## Logger handler callbacks

  @spec adding_handler(:logger.handler_config()) :: {:ok, :logger.handler_config()}
  def adding_handler(config) do
    config = Map.put(config, :config, configure(%LoggerHandler{}, Config.logger_config()))
    {:ok, config}
  end

  @spec changing_config(:update, :logger.handler_config(), :logger.handler_config()) ::
          {:ok, :logger.handler_config()}
  def changing_config(:update, old_config, _new_config) do
    new_config = Map.put(old_config, :config, configure(%LoggerHandler{}, Config.logger_config()))
    {:ok, new_config}
  end

  defp configure(%LoggerHandler{} = existing_config, config) do
    info_channel_id = Keyword.get(config, :info_channel_id)
    error_channel_id = Keyword.get(config, :error_channel_id)
    metadata = Keyword.get(config, :metadata, [])

    %{
      existing_config
      | info_channel_id: info_channel_id,
        error_channel_id: error_channel_id,
        metadata: metadata
    }
  end

  def removing_handler(_) do
    :ok
  end

  def log(%{level: log_level, meta: log_meta} = log_event, %{
        config: %LoggerHandler{} = config
      }) do
    cond do
      excluded_level?(log_level) ->
        :ok

      excluded_domain?(Map.get(log_meta, :domain, []), config.excluded_domains) ->
        :ok

      log_level == :info ->
        log_info(log_event, config)

      true ->
        log_error(log_event, config)
    end
  end

  defp excluded_level?(log_level) do
    Logger.compare_levels(log_level, :error) == :lt and log_level != :info
  end

  defp excluded_domain?(logged_domains, excluded_domains) do
    Enum.any?(logged_domains, &(&1 in excluded_domains))
  end

  # "string" logged
  defp log_info(
         %{msg: {:string, unicode_chardata}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    Client.log_info(unicode_chardata, metadata)
    :ok
  end

  # "report" here is of type logger:report/0, which is a map or keyword list.
  defp log_info(
         %{msg: {:report, report}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    message = Map.new(report)
    Client.log_info(message, metadata)
    :ok
  end

  # erlang `:logger` support this format ex `:logger.info("Hello ~s", ["world"])`
  # read more on: https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message
  defp log_info(
         %{msg: {format, format_args}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    string_message = format |> :io_lib.format(format_args) |> IO.chardata_to_string()
    Client.log_info(string_message, metadata)
    :ok
  end

  defp log_info(_log_event, %LoggerHandler{} = _config) do
    :ok
  end

  # A string was logged. We check for the :crash_reason metadata and try to build a sensible
  # report from there, otherwise we use the logged string directly.
  defp log_error(
         %{msg: {:string, unicode_chardata}, meta: meta} = log_event,
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(log_event.meta, config.metadata)
    log_from_crash_reason(meta[:crash_reason], unicode_chardata, metadata, config)
  end

  # "report" here is of type logger:report/0, which is a map or keyword list.
  defp log_error(
         %{msg: {:report, report}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)

    case Map.new(report) do
      %{reason: {exception, stacktrace}} when is_exception(exception) and is_list(stacktrace) ->
        context = Map.put(Context.get(), :metadata, metadata)
        error = Error.new(exception, stacktrace, context)
        Client.send_error(error)

      %{reason: {reason, stacktrace}} when is_list(stacktrace) ->
        context = Map.put(Context.get(), :metadata, metadata)
        error = Error.new(reason, stacktrace, context)
        Client.send_error(error)

      %{reason: reason} ->
        Client.log_error(reason, metadata)

      _ ->
        Client.log_error(inspect(report), metadata)
    end
  end

  # erlang `:logger` support this format ex `:logger.error("Hello ~s", ["world"])`
  # read more on: https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message
  defp log_error(
         %{msg: {format, format_args}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    string_message = format |> :io_lib.format(format_args) |> IO.chardata_to_string()
    Client.log_error(string_message, metadata)
    :ok
  end

  defp log_from_crash_reason(
         {exception, stacktrace},
         _chardata_message,
         metadata,
         _config
       )
       when is_exception(exception) and is_list(stacktrace) do
    context = Map.put(Context.get(), :metadata, metadata)
    error = Error.new(exception, stacktrace, context)
    Client.send_error(error)
    :ok
  end

  defp log_from_crash_reason(
         {reason, stacktrace},
         chardata_message,
         metadata,
         _config
       )
       when is_list(stacktrace) do
    context =
      Map.merge(Context.get(), %{
        extra_info_from_message: extra_info_from_message(chardata_message),
        metadata: metadata
      })

    error = Error.new(reason, stacktrace, context)
    Client.send_error(error)
    :ok
  end

  # defp log_from_crash_reason(
  #        _other_reason,
  #        chardata_message,
  #        metadata,
  #        config
  #      ) do
  #   Discord.create_message(config.error_channel_id, chardata_message, metadata)
  # end

  defp extra_info_from_message([
         [
           "GenServer ",
           _pid,
           " terminating",
           _reason,
           "\nLast message",
           _from,
           ": ",
           last_message
         ],
         "\nState: ",
         state | _rest
       ]) do
    %{genserver_state: state, last_message: last_message}
  end

  # Sometimes there's an extra sneaky [] in there.
  defp extra_info_from_message([
         [
           "GenServer ",
           _pid,
           " terminating",
           _reason,
           [],
           "\nLast message",
           _from,
           ": ",
           last_message
         ],
         "\nState: ",
         state | _rest
       ]) do
    %{genserver_state: state, last_message: last_message}
  end

  defp extra_info_from_message(_message) do
    %{}
  end

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      case Map.fetch(metadata, key) do
        {:ok, val} -> Map.put(acc, key, val)
        :error -> acc
      end
    end)
  end
end
