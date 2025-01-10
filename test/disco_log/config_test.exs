defmodule DiscoLog.ConfigTest do
  use ExUnit.Case, async: true

  alias DiscoLog.Config
  alias DiscoLog.Discord

  @example_config [
    otp_app: :foo,
    token: "discord_token",
    guild_id: "guild_id",
    category_id: "category_id",
    occurrences_channel_id: "occurrences_channel_id",
    info_channel_id: "info_channel_id",
    error_channel_id: "error_channel_id",
    enable: true,
    enable_logger: true,
    instrument_oban: true,
    instrument_phoenix: true,
    instrument_tesla: true,
    metadata: [:foo],
    excluded_domains: [:cowboy],
    before_send: {Foo, [1, 2, 3]}
  ]

  describe inspect(&Config.validate/1) do
    test "returns map" do
      assert %{} = Config.validate!(@example_config)
    end

    test "adds Discord.Config" do
      assert %{discord_config: %Discord.Config{}} = Config.validate!(@example_config)
    end
  end
end
