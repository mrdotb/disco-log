defmodule Mix.Tasks.DiscoLog.Cleanup do
  @moduledoc """
  Delete all threads and messages from channels.
  """
  use Mix.Task

  alias DiscoLog.Config
  alias DiscoLog.Discord

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)
    config = Config.read!()

    # Delete all threads from occurrences channel
    Discord.delete_threads(config.discord_client, config.guild_id, config.occurrences_channel_id)

    # Delete all messages from info and error channels
    for channel_id <- [config.info_channel_id, config.error_channel_id] do
      Discord.delete_channel_messages(config.discord_client, channel_id)
    end

    Mix.shell().info("Messages from DiscoLog Discord channels were deleted successfully!")
  end
end
