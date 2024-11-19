defmodule Mix.Tasks.DiscoLog.Cleanup do
  @moduledoc """
  Delete all threads and messages from channels.
  """
  use Mix.Task

  alias DiscoLog.Discord
  alias DiscoLog.Config

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)
    config = Config.read!().discord_config

    # Delete all threads from occurrences channel
    Discord.delete_threads(config, config.occurrences_channel_id)

    # Delete all messages from info and error channels
    [
      config.info_channel_id,
      config.error_channel_id
    ]
    |> Enum.each(&Discord.delete_channel_messages(config, &1))

    Mix.shell().info("Messages from DiscoLog Discord channels were deleted successfully!")
  end
end
