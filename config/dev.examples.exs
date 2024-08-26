import Config

config :disco_log,
  otp_app: :disco_log,
  token: "",
  guild_id: "",
  category_id: "",
  occurrences_channel_id: "",
  occurrences_channel_tags: %{
    "plug" => "",
    "live_view" => "",
    "oban" => ""
  },
  info_channel_id: "",
  error_channel_id: "",
  enable_logger: true,
  instrument_oban: true,
  instrument_phoenix: true,
  metadata: []

config :logger,
  # backends: [],
  # Usefull when debugging logger
  backends: [:console],
  compile_time_purge_matching: [
    # Usefull for debugging purposes when doing real discord request and it's too verbose
    # [module: DiscoLog.Discord.Client, level_lower_than: :info]
  ],
  truncate: :infinity
