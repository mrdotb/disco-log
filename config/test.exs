import Config

config :disco_log,
  enable: false,
  otp_app: :disco_log,
  token: "",
  guild_id: "",
  category_id: "",
  occurrences_channel_id: "",
  info_channel_id: "",
  error_channel_id: "",
  discord_client_module: DiscoLog.Discord.API.Mock,
  websocket_adapter: DiscoLog.WebsocketClient.Mock,
  enable_presence: true

config :logger,
  backends: [],
  # Usefull when debugging logger
  # backends: [:console],
  compile_time_purge_matching: [
    # Usefull for debugging purposes when doing real discord request
    # [module: DiscoLog.Discord.Client, level_lower_than: :info]
  ],
  truncate: :infinity
