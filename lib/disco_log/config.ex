defmodule DiscoLog.Config do
  alias DiscoLog.Discord

  @configuration_schema [
    otp_app: [
      type: :atom,
      required: true,
      doc: "Name of your application"
    ],
    token: [
      type: :string,
      required: true,
      doc: "Your Discord bot token"
    ],
    guild_id: [
      type: :string,
      required: true,
      doc: "Discord Server ID"
    ],
    category_id: [
      type: :string,
      required: true,
      doc: "Category (Channel) ID"
    ],
    occurrences_channel_id: [
      type: :string,
      required: true,
      doc: "Forum channel ID for error occurrences"
    ],
    occurrences_channel_tags: [
      type: {:map, :string, :string},
      required: true,
      doc: "Map with IDs for \"plug\", \"live_view\" and \"oban\" tags"
    ],
    info_channel_id: [
      type: :string,
      required: true,
      doc: "Text channel ID for info-level logs"
    ],
    error_channel_id: [
      type: :string,
      required: true,
      doc: "Text channel ID for logs higher than info-level logs"
    ],
    enable: [
      type: :boolean,
      default: true,
      doc: "Automatically start DiscoLog?"
    ],
    enable_logger: [
      type: :boolean,
      default: true,
      doc: "Automatically attach logger handler?"
    ],
    enable_discord_log: [
      type: :boolean,
      default: false,
      doc: "Logs requests to Discord API?"
    ],
    instrument_oban: [
      type: :boolean,
      default: true,
      doc: "Automatically instrument Oban?"
    ],
    instrument_phoenix: [
      type: :boolean,
      default: true,
      doc: "Automatically instrument Phoenix?"
    ],
    instrument_tesla: [
      type: :boolean,
      default: true,
      doc: "Automatically instrument Tesla?"
    ],
    metadata: [
      type: {:list, :atom},
      default: [],
      doc: "List of Logger metadata keys to propagate with the message"
    ],
    excluded_domains: [
      type: {:list, :atom},
      default: [:cowboy, :bandit],
      doc: "Logs with domains from this list will be ignored"
    ],
    before_send: [
      type: {:or, [nil, :mod_arg, {:fun, 1}]},
      default: nil,
      doc:
        "This callback will be called with error or {message, metadata} tuple as argument before it is sent"
    ],
    discord: [
      type: :atom,
      default: DiscoLog.Discord,
      doc: "Discord client to use"
    ],
    supervisor_name: [
      type: :atom,
      default: DiscoLog,
      doc: "Name of the supervisor process running DiscoLog"
    ]
  ]

  @compiled_schema NimbleOptions.new!(@configuration_schema)

  @moduledoc """
  Configuration related module for DiscoLog.

  ## Configuration Schema

  #{NimbleOptions.docs(@compiled_schema)}
  """

  @type config() :: map()

  @doc """
  Reads and validates config from global application configuration
  """
  @spec read!() :: config()
  def read!() do
    raw_options =
      Application.get_all_env(:disco_log) |> Keyword.take(Keyword.keys(@configuration_schema))

    case Keyword.get(raw_options, :enable) do
      false -> %{enable: false}
      _ -> validate!(raw_options)
    end
  end

  @doc """
  See `validate/1`
  """
  @spec validate!(options :: keyword() | map()) :: config()
  def validate!(options) do
    {:ok, config} = validate(options)
    config
  end

  @doc """
  Validates configuration against the schema
  """
  @spec validate(options :: keyword() | map()) ::
          {:ok, config()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(%{discord_config: _} = config) do
    config
    |> Map.delete(:discord_config)
    |> validate()
  end

  def validate(raw_options) do
    with {:ok, validated} <- NimbleOptions.validate(raw_options, @compiled_schema) do
      config =
        validated
        |> Map.new()
        |> then(fn config ->
          Map.put(config, :discord_config, Discord.Config.new(config))
        end)

      {:ok, config}
    end
  end
end
