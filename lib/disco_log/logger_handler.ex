defmodule DiscoLog.LoggerHandler do
  @moduledoc false
  @behaviour :logger_handler

  alias DiscoLog.Error
  alias DiscoLog.Context

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

      true ->
        metadata = Map.take(log_meta, config.metadata)
        message = message(log_event)

        case log_event do
          %{level: :info} ->
            DiscoLog.log_info(message, metadata, config)

          %{meta: %{crash_reason: crash_reason}} ->
            error =
              Error.new(crash_reason)
              |> Error.enrich(config)
              |> Map.put(:display_full_error, message)

            context = Map.merge(Context.get(), metadata)

            DiscoLog.log_occurrence(
              error,
              context,
              config
            )

          _ ->
            DiscoLog.log_error(message, metadata, config)
        end
    end
  end

  defp excluded_level?(log_level) do
    Logger.compare_levels(log_level, :error) == :lt and log_level != :info
  end

  defp excluded_domain?(logged_domains, excluded_domains) do
    Enum.any?(logged_domains, &(&1 in excluded_domains))
  end

  defp message(%{msg: {:string, chardata}}), do: IO.iodata_to_binary(chardata)

  defp message(%{msg: {:report, report}, meta: %{report_cb: report_cb}})
       when is_function(report_cb, 1) do
    {io_format, data} = report_cb.(report)
    io_format |> :io_lib.format(data) |> IO.iodata_to_binary()
  end

  defp message(%{msg: {:report, report}}), do: inspect(report, limit: :infinity, pretty: true)

  defp message(%{msg: {io_format, data}}),
    do: io_format |> :io_lib.format(data) |> IO.iodata_to_binary()
end
