defmodule DiscoLog.ConfigTest do
  use ExUnit.Case, async: true

  alias DiscoLog.Config

  @example_config [
    otp_app: :logger,
    token: "discord_token",
    guild_id: "guild_id",
    category_id: "category_id",
    occurrences_channel_id: "occurrences_channel_id",
    info_channel_id: "info_channel_id",
    error_channel_id: "error_channel_id",
    enable: true,
    enable_logger: true,
    instrument_oban: true,
    metadata: [:foo],
    excluded_domains: [:cowboy],
    go_to_repo_top_modules: ["DemoWeb"]
  ]

  describe inspect(&Config.validate/1) do
    test "returns map" do
      assert %{} = Config.validate!(@example_config)
    end

    test "adds discord_client" do
      assert %{discord_client: %DiscoLog.Discord.API{}} = Config.validate!(@example_config)
    end

    test "adds in_app_modules" do
      assert %{in_app_modules: modules} = Config.validate!(@example_config)
      assert Logger in modules
    end
  end
end
