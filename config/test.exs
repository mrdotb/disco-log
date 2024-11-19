import Config

config :disco_log,
  enable: false,
  otp_app: :disco_log,
  token: "",
  guild_id: "",
  category_id: "",
  occurrences_channel_id: "",
  occurrences_channel_tags: %{
    "plug" => "",
    "phoenix" => "",
    "liveview" => "",
    "oban" => ""
  },
  info_channel_id: "",
  error_channel_id: "",
  discord: DiscoLog.DiscordMock

config :logger,
  backends: [],
  # Usefull when debugging logger
  # backends: [:console],
  compile_time_purge_matching: [
    # Usefull for debugging purposes when doing real discord request
    # [module: DiscoLog.Discord.Client, level_lower_than: :info]
  ],
  truncate: :infinity
