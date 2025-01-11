defmodule DiscoLog.LoggerHandler do
  @moduledoc """
  A logger handler [`:logger` handler](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#handlers)

  Original source: https://github.com/getsentry/sentry-elixir/blob/69ac8d0e3f33ff36ab1092bbd346fdb99cf9d061/lib/sentry/logger_handler.ex
  """
  @behaviour :logger_handler

  alias DiscoLog.Context
  alias DiscoLog.Error

  ## Logger handler callbacks

  @impl :logger_handler
  def log(%{level: log_level, meta: log_meta} = log_event, %{
        config: config
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
         config
       ) do
    metadata = take_metadata(meta, config.metadata)
    message = IO.iodata_to_binary(unicode_chardata)
    DiscoLog.log_info(message, metadata, config)
  end

  # "report" here is of type logger:report/0, which is a struct, map or keyword list.
  defp log_info(
         %{msg: {:report, report}, meta: meta},
         config
       ) do
    metadata = take_metadata(meta, config.metadata)
    log_info_report(report, metadata, config)
  end

  # erlang `:logger` support this format ex `:logger.info("Hello ~s", ["world"])`
  # read more on: https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message
  defp log_info(
         %{msg: {format, format_args}, meta: meta},
         config
       ) do
    metadata = take_metadata(meta, config.metadata)
    string_message = format |> :io_lib.format(format_args) |> IO.chardata_to_string()
    DiscoLog.log_info(string_message, metadata, config)
  end

  defp log_info(_log_event, _config) do
    :ok
  end

  # A string was logged. We check for the :crash_reason metadata and try to build a sensible
  # report from there, otherwise we use the logged string directly.
  defp log_error(
         %{msg: {:string, unicode_chardata}, meta: meta} = log_event,
         config
       ) do
    metadata = take_metadata(log_event.meta, config.metadata)
    log_from_crash_reason(meta[:crash_reason], unicode_chardata, metadata, config)
  end

  # "report" here is of type logger:report/0, which is a struct, map or keyword list.
  defp log_error(
         %{msg: {:report, report}, meta: meta},
         config
       ) do
    metadata = take_metadata(meta, config.metadata)
    log_error_report(report, metadata, config)
  end

  # erlang `:logger` support this format ex `:logger.error("Hello ~s", ["world"])`
  # read more on: https://www.erlang.org/doc/apps/kernel/logger_chapter.html#log-message
  defp log_error(
         %{msg: {format, format_args}, meta: meta},
         config
       ) do
    metadata = take_metadata(meta, config.metadata)
    string_message = format |> :io_lib.format(format_args) |> IO.chardata_to_string()
    DiscoLog.log_error(string_message, metadata, config)
  end

  defp log_error(_log_event, _config) do
    :ok
  end

  defp log_from_crash_reason(
         {exception, stacktrace},
         _chardata_message,
         metadata,
         config
       )
       when is_exception(exception) and is_list(stacktrace) do
    context = Map.put(Context.get(), :metadata, metadata)
    error = Error.new(exception, stacktrace, context, config)
    DiscoLog.send_error(error, config)
  end

  defp log_from_crash_reason(
         {reason, stacktrace},
         chardata_message,
         metadata,
         config
       )
       when is_list(stacktrace) do
    context =
      Map.merge(Context.get(), %{
        extra_info_from_message: extra_info_from_message(chardata_message),
        metadata: metadata
      })

    error =
      case reason do
        {type, {GenServer, :call, [_pid, _call, _timeout]}} = reason
        when type in [:noproc, :timeout] ->
          reason = Exception.format_exit(reason)
          context = Map.put(context, :extra_reason, reason)
          Error.new({"genserver_call", type}, stacktrace, context, config)

        _other ->
          case try_to_parse_message(chardata_message) do
            nil ->
              reason = inspect(reason)
              Error.new({"genserver", reason}, stacktrace, context, config)

            %{reason: reason} = parsed_message ->
              context =
                Map.put(context, :extra_info_from_genserver, Map.delete(parsed_message, :reason))

              Error.new({"genserver", reason}, stacktrace, context, config)
          end
      end

    DiscoLog.send_error(error, config)
  end

  defp log_from_crash_reason(
         _other_reason,
         chardata_message,
         metadata,
         config
       ) do
    message = IO.iodata_to_binary(chardata_message)
    DiscoLog.log_error(message, metadata, config)
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
      reason: string_reason,
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
      reason: string_reason,
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message([
         [
           "GenServer ",
           _module,
           " terminating"
         ],
         reason,
         "\nLast message: ",
         inspected_last_message,
         "\nState: ",
         inspected_state
       ]) do
    string_reason = reason |> :unicode.characters_to_binary() |> String.trim()

    %{
      reason: string_reason,
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message([
         [
           "GenServer ",
           _module,
           " terminating",
           reason,
           [],
           "\nLast message",
           [],
           ": ",
           inspected_last_message
         ],
         "\nState: ",
         inspected_state
       ]) do
    string_reason = reason |> :unicode.characters_to_binary() |> String.trim()

    %{
      reason: string_reason,
      last_message: inspected_last_message,
      message: "GenServer %{} terminating: #{string_reason}",
      state: inspected_state
    }
  end

  defp try_to_parse_message(_chardata_message) do
    nil
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

  defp log_info_report(report, metadata, config) when is_struct(report) do
    report
    |> Map.from_struct()
    |> Map.put(:__struct__, to_string(report.__struct__))
    |> DiscoLog.log_info(metadata, config)
  end

  defp log_info_report(report, metadata, config) do
    report
    |> Map.new()
    |> DiscoLog.log_info(metadata, config)
  end

  defp log_error_report(report, metadata, config) when is_struct(report) do
    report
    |> Map.from_struct()
    |> Map.put(:__struct__, to_string(report.__struct__))
    |> DiscoLog.log_error(metadata, config)
  end

  defp log_error_report(report, metadata, config) do
    case Map.new(report) do
      %{reason: {exception, stacktrace}} when is_exception(exception) and is_list(stacktrace) ->
        context = Map.put(Context.get(), :metadata, metadata)
        error = Error.new(exception, stacktrace, context, config)
        DiscoLog.send_error(error, config)

      %{reason: {reason, stacktrace}} when is_list(stacktrace) ->
        context = Map.put(Context.get(), :metadata, metadata)
        error = Error.new(reason, stacktrace, context, config)
        DiscoLog.send_error(error, config)

      %{reason: reason} ->
        DiscoLog.log_error(reason, metadata, config)

      report ->
        DiscoLog.log_error(report, metadata, config)
    end
  end
end
