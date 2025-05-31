defmodule DiscoLog.ConfigTest do
  use ExUnit.Case, async: true

  alias DiscoLog.Config

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
    instrument_tesla: true,
    metadata: [:foo],
    excluded_domains: [:cowboy]
  ]

  describe inspect(&Config.validate/1) do
    test "returns map" do
      assert %{} = Config.validate!(@example_config)
    end

    test "adds discord_client" do
      assert %{discord_client: %DiscoLog.Discord.API{}} = Config.validate!(@example_config)
    end
  end
end
