defmodule DiscoLog.DiscordBehaviour do
  @moduledoc false
  @callback list_channels(opts :: Keyword.t()) :: {:ok, list(any)} | {:error, String.t()}

  @callback fetch_or_create_channel(
              channels :: list(any),
              channel_config :: map(),
              parent_id :: nil | String.t()
            ) :: {:ok, map()} | {:error, String.t()}

  @callback maybe_delete_channel(channels :: list(any), channel_config :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @callback create_occurrence_thread(error :: String.t()) :: {:ok, map()} | {:error, String.t()}

  @callback create_occurrence_message(thread_id :: String.t(), error :: String.t()) ::
              {:ok, map()} | {:error, String.t()}

  @callback list_occurrence_threads() :: list(any)

  @callback delete_channel_messages(channel_id :: String.t()) ::
              list(any)

  @callback create_message(channel_id :: String.t(), message :: String.t(), metadata :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @callback delete_threads(channel_id :: String.t()) :: list(any)
end

defmodule DiscoLog.DiscordImpl do
  @moduledoc """
  Abstraction over Discord api
  """
  @behaviour DiscoLog.DiscordBehaviour

  alias DiscoLog.Discord

  @impl true
  defdelegate list_channels(channels), to: Discord.Client

  @impl true
  defdelegate fetch_or_create_channel(channels, channel_config, parent_id),
    to: Discord.Context

  @impl true
  defdelegate maybe_delete_channel(channels, channel_config), to: Discord.Context

  @impl true
  defdelegate create_occurrence_thread(error), to: Discord.Context

  @impl true
  defdelegate create_occurrence_message(thread_id, error), to: Discord.Context

  @impl true
  defdelegate list_occurrence_threads(), to: Discord.Context

  @impl true
  defdelegate delete_channel_messages(channel_id), to: Discord.Context

  @impl true
  defdelegate create_message(channel_id, message, metadata), to: Discord.Context

  @impl true
  defdelegate delete_threads(channel_id), to: Discord.Context
end

defmodule DiscoLog.Discord do
  @moduledoc false

  def list_channels(opts \\ []), do: impl().list_channels(opts)

  def fetch_or_create_channel(channels, channel_config, parent_id \\ nil),
    do: impl().fetch_or_create_channel(channels, channel_config, parent_id)

  def maybe_delete_channel(channels, channel_config),
    do: impl().maybe_delete_channel(channels, channel_config)

  def create_occurrence_thread(error), do: impl().create_occurrence_thread(error)

  def create_occurrence_message(thread_id, error),
    do: impl().create_occurrence_message(thread_id, error)

  def list_occurrence_threads, do: impl().list_occurrence_threads()

  def delete_channel_messages(channel_id), do: impl().delete_channel_messages(channel_id)

  def create_message(channel_id, message, metadata),
    do: impl().create_message(channel_id, message, metadata)

  def delete_threads(channel_id), do: impl().delete_threads(channel_id)

  defp impl, do: Application.get_env(:disco_log, :discord, DiscoLog.DiscordImpl)
end
