defmodule Mix.Tasks.DiscoLog.Drop do
  @moduledoc """
  Delete the discord channels used by DiscoLog if they exist.
  """
  use Mix.Task

  alias DiscoLog.Discord
  alias DiscoLog.Config

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)

    config = Config.read!().discord_config

    {:ok, channels} = Discord.list_channels(config.config)

    [
      config.category,
      config.occurrences_channel,
      config.info_channel,
      config.error_channel
    ]
    |> Enum.each(&Discord.maybe_delete_channel(config, channels, &1))

    Mix.shell().info("Discord channels for DiscoLog were deleted successfully!")
  end
end
