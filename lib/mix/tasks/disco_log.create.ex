defmodule Mix.Tasks.DiscoLog.Create do
  @moduledoc """
  Creates the necessary discord channels for DiscoLog.
  """
  use Mix.Task

  alias DiscoLog.Discord

  @impl Mix.Task
  def run(_args) do
    # Ensure req is started
    {:ok, _} = Application.ensure_all_started(:req)

    with {:ok, channels} <- Discord.list_channels(),
         {:ok, category} <- Discord.fetch_or_create_channel(channels, Discord.Config.category()),
         {:ok, occurrence} <-
           Discord.fetch_or_create_channel(
             channels,
             Discord.Config.occurrences_channel(),
             category["id"]
           ),
         {:ok, info} <-
           Discord.fetch_or_create_channel(
             channels,
             Discord.Config.info_channel(),
             category["id"]
           ),
         {:ok, error} <-
           Discord.fetch_or_create_channel(
             channels,
             Discord.Config.error_channel(),
             category["id"]
           ) do
      Mix.shell().info("Discord channels for DiscoLog were created successfully!")
      Mix.shell().info("Complete the configuration by adding the following to your config")

      Mix.shell().info("""
      config :disco_log,
        otp_app: :app_name,
        token: "#{Discord.Config.token()}",
        guild_id: "#{Discord.Config.guild_id()}",
        category_id: "#{category["id"]}",
        occurrences_channel_id: "#{occurrence["id"]}",
        occurrences_channel_tags: %{#{Enum.map_join(occurrence["available_tags"], ", ", fn tag -> "\"#{tag["name"]}\" => \"#{tag["id"]}\"" end)}},
        info_channel_id: "#{info["id"]}",
        error_channel_id: "#{error["id"]}"
      """)
    end
  end
end
