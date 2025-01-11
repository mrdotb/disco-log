defmodule Mix.Tasks.DiscoLog.Drop do
  @moduledoc """
  Delete the discord channels used by DiscoLog if they exist.
  """
  use Mix.Task

  alias DiscoLog.Config
  alias DiscoLog.Discord.API

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)

    config = Config.read!()

    for channel_id <- [
          config.category_id,
          config.occurrences_channel_id,
          config.info_channel_id,
          config.error_channel_id
        ] do
      API.delete_channel(config.discord_client, channel_id)
    end

    Mix.shell().info("Discord channels for DiscoLog were deleted successfully!")
  end
end
