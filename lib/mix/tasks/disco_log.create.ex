defmodule Mix.Tasks.DiscoLog.Create do
  @moduledoc """
  Creates the necessary discord channels for DiscoLog.
  """
  use Mix.Task

  alias DiscoLog.Discord
  alias DiscoLog.Config

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)
    config = Config.read!().discord_config

    with {:ok, channels} <- Discord.list_channels(config),
         {:ok, category} <- Discord.fetch_or_create_channel(config, channels, config.category),
         {:ok, occurrence} <-
           Discord.fetch_or_create_channel(
             config,
             channels,
             config.occurrences_channel,
             category["id"]
           ),
         {:ok, info} <-
           Discord.fetch_or_create_channel(
             config,
             channels,
             config.info_channel,
             category["id"]
           ),
         {:ok, error} <-
           Discord.fetch_or_create_channel(
             config,
             channels,
             config.error_channel,
             category["id"]
           ) do
      Mix.shell().info("Discord channels for DiscoLog were created successfully!")
      Mix.shell().info("Complete the configuration by adding the following to your config")

      Mix.shell().info("""
      config :disco_log,
        otp_app: :app_name,
        token: "#{config.token}",
        guild_id: "#{config.guild_id}",
        category_id: "#{category["id"]}",
        occurrences_channel_id: "#{occurrence["id"]}",
        occurrences_channel_tags: %{#{Enum.map_join(occurrence["available_tags"], ", ", fn tag -> "\"#{tag["name"]}\" => \"#{tag["id"]}\"" end)}},
        info_channel_id: "#{info["id"]}",
        error_channel_id: "#{error["id"]}"
      """)
    end
  end
end
