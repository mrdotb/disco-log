defmodule DiscoLog.Logger do
  @moduledoc """
  Simple logger backend that sends logs to a Discord channel based on the log
  level.
  It only supports :info and :error levels.
  For the :error level, if the error metadata contains a `:crash_reason` key it
  will be ignored since the ErrorBackend handle it and it will be duplicated.
  """

  alias DiscoLog.Config
  alias DiscoLog.Discord

  require Logger

  @behaviour :gen_event

  defstruct info_channel_id: nil,
            info_format: nil,
            error_channel_id: nil,
            error_format: nil,
            metadata: nil

  @default_format "$time $metadata[$level] $message\n"

  @impl true
  def init(_opts) do
    {:ok, configure(%__MODULE__{})}
  end

  def attach do
    case LoggerBackends.add(__MODULE__) do
      {:error, error} ->
        Logger.warning("DiscoLog.Logger not attached to Logger: #{error}")
        :error

      {:ok, _} ->
        Logger.debug("DiscoLog.Logger attached to Logger")
        :ok
    end
  end

  @impl true
  def handle_call({:configure, _options}, state) do
    {:ok, :ok, configure(state)}
  end

  @impl true
  def handle_event(
        {:info, gl, {Logger, msg, ts, md}},
        %{info_channel_id: channel_id, info_format: format, metadata: keys} = state
      )
      when node(gl) != node() do
    message =
      format
      |> Logger.Formatter.format(:info, msg, ts, take_metadata(md, keys))
      |> IO.iodata_to_binary()

    Discord.create_message(channel_id, message)
    {:ok, state}
  end

  def handle_event({:error, gl, {Logger, msg, ts, md}}, state) when node(gl) != node() do
    md
    |> Enum.into(%{})
    |> handle_error_report(msg, ts, state)

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  # This is a no-op since the ErrorBackend handle it
  defp handle_error_report(%{crash_reason: _}, _msg, _ts, _state) do
    :ok
  end

  defp handle_error_report(md, msg, ts, %{
         error_channel_id: channel_id,
         error_format: format,
         metadata: keys
       }) do
    message =
      format
      |> Logger.Formatter.format(:error, msg, ts, take_metadata(md, keys))
      |> IO.iodata_to_binary()

    Discord.create_message(channel_id, message)
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    metadatas =
      Enum.reduce(keys, [], fn key, acc ->
        case Keyword.fetch(metadata, key) do
          {:ok, val} -> [{key, val} | acc]
          :error -> acc
        end
      end)

    Enum.reverse(metadatas)
  end

  defp configure(state) do
    config = Config.logger_config()

    info_channel_id = Keyword.get(config, :info_channel_id)
    info_format_opts = Keyword.get(config, :info_format, @default_format)
    info_format = Logger.Formatter.compile(info_format_opts)

    error_channel_id = Keyword.get(config, :error_channel_id)
    error_format_opts = Keyword.get(config, :error_format, @default_format)
    error_format = Logger.Formatter.compile(error_format_opts)

    metadata = Keyword.get(config, :metadata, :all)

    state = %{
      state
      | info_channel_id: info_channel_id,
        info_format: info_format,
        error_channel_id: error_channel_id,
        error_format: error_format,
        metadata: metadata
    }

    env =
      state
      |> Map.from_struct()
      |> Keyword.new()

    Application.put_env(:logger, __MODULE__, env)

    state
  end
end
