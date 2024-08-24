defmodule Mix.Tasks.DiscoLog.Drop do
  @moduledoc """
  Delete the discord channels used by DiscoLog if they exist.
  """
  use Mix.Task

  alias DiscoLog.Discord

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)

    {:ok, channels} = Discord.list_channels()

    [
      Discord.Config.category(),
      Discord.Config.occurrences_channel(),
      Discord.Config.info_channel(),
      Discord.Config.error_channel()
    ]
    |> Enum.each(&Discord.maybe_delete_channel(channels, &1))

    Mix.shell().info("Discord channels for DiscoLog were deleted successfully!")
  end
end
