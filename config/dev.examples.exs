import Config

config :disco_log,
  otp_app: :disco_log,
  token: "",
  guild_id: "",
  category_id: "",
  occurrences_channel_id: "",
  info_channel_id: "",
  error_channel_id: "",
  enable_logger: true,
  instrument_oban: true,
  metadata: [:extra],
  enable_go_to_repo: true,
  repo_url: "https://github.com/mrdotb/disco-log/blob",
  # a real git sha is better but for testing purposes you can use a branch
  git_sha: "main"

config :logger,
  # backends: [],
  # Usefull when debugging logger
  backends: [:console],
  compile_time_purge_matching: [
    # Usefull for debugging purposes when doing real discord request and it's too verbose
    # [module: DiscoLog.Discord.Client, level_lower_than: :info]
  ],
  truncate: :infinity
