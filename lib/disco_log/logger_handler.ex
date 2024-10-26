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
            metadata: []

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
    metadata = Keyword.get(config, :metadata, [])

    %{
      existing_config
      | metadata: metadata
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

      log_level == :info and Map.get(log_meta, :application) == :phoenix ->
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
    message = IO.iodata_to_binary(unicode_chardata)
    Client.log_info(message, metadata)
    :ok
  end

  # "report" here is of type logger:report/0, which is a struct, map or keyword list.
  defp log_info(
         %{msg: {:report, report}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    log_info_report(report, metadata)
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
    log_from_crash_reason(meta[:crash_reason], unicode_chardata, metadata)
  end

  # "report" here is of type logger:report/0, which is a struct, map or keyword list.
  defp log_error(
         %{msg: {:report, report}, meta: meta},
         %LoggerHandler{} = config
       ) do
    metadata = take_metadata(meta, config.metadata)
    log_error_report(report, metadata)
    :ok
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

  defp log_error(_log_event, %LoggerHandler{} = _config) do
    :ok
  end

  defp log_from_crash_reason(
         {exception, stacktrace},
         _chardata_message,
         metadata
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
         metadata
       )
       when is_list(stacktrace) do
    context =
      Map.merge(Context.get(), %{
        extra_info_from_message: extra_info_from_message(chardata_message),
        metadata: metadata
      })

    case reason do
      {type, {GenServer, :call, [_pid, _call, _timeout]}} = reason
      when type in [:noproc, :timeout] ->
        reason = Exception.format_exit(reason)
        context = Map.put(context, :extra_reason, reason)
        error = Error.new({"genserver_call", type}, stacktrace, context)
        Client.send_error(error)

      _other ->
        context =
          Map.put(context, :extra_info_from_genserver, try_to_parse_message(chardata_message))

        error = Error.new(reason, stacktrace, context)
        Client.send_error(error)
    end

    :ok
  end

  defp log_from_crash_reason(
         _other_reason,
         chardata_message,
         metadata
       ) do
    message = IO.iodata_to_binary(chardata_message)
    Client.log_error(message, metadata)
    :ok
  end

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

  # We do this because messages from Erlang's gen_* behaviours are often full of interesting
  # and useful data. For example, GenServer messages contain the PID, the reason, the last
  # message, and a treasure trove of stuff. If we cannot parse the message, such is life
  # and we just report it as is.
  defp try_to_parse_message([
         [
           "GenServer ",
           _inspected_pid,
           " terminating",
           chardata_reason,
           _whatever_this_is = [],
           "\nLast message",
           [" (from ", _inspected_sender_pid, ")"],
           ": ",
           inspected_last_message
         ],
         "\nState: ",
         inspected_state | _
       ]) do
    string_reason = chardata_reason |> :unicode.characters_to_binary() |> String.trim()

    %{
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message([
         [
           "GenServer ",
           _inspected_pid,
           " terminating",
           chardata_reason,
           "\nLast message",
           [" (from ", _inspected_sender_pid, ")"],
           ": ",
           inspected_last_message
         ],
         "\nState: ",
         inspected_state | _
       ]) do
    string_reason = chardata_reason |> :unicode.characters_to_binary() |> String.trim()

    %{
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message([
         [
           "GenServer ",
           _inspected_pid,
           " terminating",
           chardata_reason,
           "\nLast message: ",
           inspected_last_message
         ],
         "\nState: ",
         inspected_state | _
       ]) do
    string_reason = chardata_reason |> :unicode.characters_to_binary() |> String.trim()

    %{
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message(_chardata_message) do
    %{}
  end

  # Some metadata like PID are not serializable to JSON a better approach is
  # needed
  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      case Map.fetch(metadata, key) do
        {:ok, val} -> Map.put(acc, key, val)
        :error -> acc
      end
    end)
  end

  defp log_info_report(report, metadata) when is_struct(report) do
    report
    |> Map.from_struct()
    |> Map.put(:__struct__, to_string(report.__struct__))
    |> Client.log_info(metadata)
  end

  defp log_info_report(report, metadata) do
    report
    |> Map.new()
    |> Client.log_info(metadata)
  end

  defp log_error_report(report, metadata) when is_struct(report) do
    report
    |> Map.from_struct()
    |> Map.put(:__struct__, to_string(report.__struct__))
    |> Client.log_error(metadata)
  end

  defp log_error_report(report, metadata) do
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
        Client.log_error(report, metadata)
    end
  end
end
