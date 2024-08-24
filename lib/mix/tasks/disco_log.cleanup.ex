defmodule Mix.Tasks.DiscoLog.Cleanup do
  @moduledoc """
  Delete all threads and messages from channels.
  """
  use Mix.Task

  alias DiscoLog.Discord

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)

    # Delete all threads from occurrences channel
    Discord.Config.occurrences_channel_id()
    |> Discord.delete_threads()

    # Delete all messages from info and error channels
    [
      Discord.Config.info_channel_id(),
      Discord.Config.error_channel_id()
    ]
    |> Enum.each(&Discord.delete_channel_messages(&1))

    Mix.shell().info("Messages from DiscoLog Discord channels were deleted successfully!")
  end
end
