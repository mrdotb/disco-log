defmodule DiscoLog.Discord do
  @moduledoc """
  Abstraction over Discord api
  """

  alias __MODULE__

  defdelegate list_channels(opts \\ []), to: Discord.Client

  defdelegate fetch_or_create_channel(channels, channel_config, parent_id \\ nil),
    to: Discord.Context

  defdelegate maybe_delete_channel(channels, channel_config), to: Discord.Context

  defdelegate create_occurrence_thread(error), to: Discord.Context

  defdelegate create_occurrence_message(thread_id, error), to: Discord.Context

  defdelegate list_occurence_threads(), to: Discord.Context

  defdelegate delete_channel_messages(channel_id), to: Discord.Context

  defdelegate create_message(channel_id, message), to: Discord.Context

  defdelegate delete_threads(channel_id), to: Discord.Context
end
