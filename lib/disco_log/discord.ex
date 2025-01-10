defmodule DiscoLog.DiscordBehaviour do
  @moduledoc false
  @type config :: %DiscoLog.Discord.Config{}

  @callback list_channels(config()) :: {:ok, list(any)} | {:error, String.t()}

  @callback fetch_or_create_channel(
              config(),
              channels :: list(any),
              channel_config :: map(),
              parent_id :: nil | String.t()
            ) :: {:ok, map()} | {:error, String.t()}

  @callback maybe_delete_channel(config(), channels :: list(any), channel_config :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @callback create_occurrence_thread(config(), error :: String.t()) ::
              {:ok, map()} | {:error, String.t()}

  @callback create_occurrence_message(config(), thread_id :: String.t(), error :: String.t()) ::
              {:ok, map()} | {:error, String.t()}

  @callback list_occurrence_threads(config(), occurrence_channel_id :: String.t()) :: list(any)

  @callback delete_channel_messages(config(), channel_id :: String.t()) ::
              list(any)

  @callback create_message(
              config(),
              channel_id :: String.t(),
              message :: String.t(),
              metadata :: map()
            ) ::
              {:ok, map()} | {:error, String.t()}

  @callback delete_threads(config(), channel_id :: String.t()) :: list(any)

  @callback get_gateway(config()) :: {:ok, String.t()} | {:error, String.t()}

  @callback list_tags(config(), occurence_channel_id :: String.t()) :: map()
end

defmodule DiscoLog.Discord do
  @moduledoc """
  Abstraction over Discord api
  """
  @behaviour DiscoLog.DiscordBehaviour

  alias DiscoLog.Discord

  @impl true
  def list_channels(config), do: Discord.Client.list_channels(config)

  @impl true
  defdelegate fetch_or_create_channel(config, channels, channel_config, parent_id \\ nil),
    to: Discord.Context

  @impl true
  defdelegate maybe_delete_channel(config, channels, channel_config), to: Discord.Context

  @impl true
  defdelegate create_occurrence_thread(config, error), to: Discord.Context

  @impl true
  defdelegate create_occurrence_message(config, thread_id, error), to: Discord.Context

  @impl true
  defdelegate list_occurrence_threads(config, occurrence_channel_id), to: Discord.Context

  @impl true
  defdelegate delete_channel_messages(config, channel_id), to: Discord.Context

  @impl true
  defdelegate create_message(config, channel_id, message, metadata), to: Discord.Context

  @impl true
  defdelegate delete_threads(config, channel_id), to: Discord.Context

  @impl true
  defdelegate get_gateway(config), to: Discord.Context

  @impl true
  defdelegate list_tags(config, occurence_channel_id), to: Discord.Context
end
