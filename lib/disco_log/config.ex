defmodule DiscoLog.Config do
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
      doc: "Log requests to Discord API?"
    ],
    enable_presence: [
      type: :boolean,
      default: false,
      doc: "Show DiscoLog bot status as Online?"
    ],
    instrument_oban: [
      type: :boolean,
      default: true,
      doc: "Automatically instrument Oban?"
    ],
    metadata: [
      type: {:list, :atom},
      default: [],
      doc: "List of Logger metadata keys to propagate with the message"
    ],
    excluded_domains: [
      type: {:list, :atom},
      default: [:cowboy],
      doc: "Logs with domains from this list will be ignored"
    ],
    discord_client_module: [
      type: :atom,
      default: DiscoLog.Discord.API.Client,
      doc: "Discord client to use"
    ],
    supervisor_name: [
      type: :atom,
      default: DiscoLog,
      doc: "Name of the supervisor process running DiscoLog"
    ],
    presence_status: [
      type: :string,
      default: "🪩 Disco Logging",
      doc: "A message to display as the bot's status when presence is enabled"
    ],
    enable_go_to_repo: [
      type: :boolean,
      default: false,
      doc: "Enable go_to_repo feature?"
    ],
    go_to_repo_top_modules: [
      type: {:list, :string},
      default: [],
      doc:
        "List of top-level modules that are not part of the application spec but code belongs to the app"
    ],
    repo_url: [
      type: :string,
      default: "",
      doc: "URL to the git repository viewer"
    ],
    git_sha: [
      type: :string,
      default: "",
      doc: "The git SHA of the running app"
    ]
  ]

  @compiled_schema NimbleOptions.new!(@configuration_schema)

  @moduledoc """
  DiscoLog configuration

  ## Configuration Schema

  #{NimbleOptions.docs(@compiled_schema)}
  """

  @type t() :: %{
          otp_app: atom(),
          token: String.t(),
          guild_id: String.t(),
          category_id: String.t(),
          occurrences_channel_id: String.t(),
          info_channel_id: String.t(),
          error_channel_id: String.t(),
          enable: boolean(),
          enable_logger: boolean(),
          enable_discord_log: boolean(),
          enable_presence: boolean(),
          instrument_oban: boolean(),
          metadata: [atom()],
          excluded_domains: [atom()],
          discord_client_module: module(),
          supervisor_name: supervisor_name(),
          presence_status: String.t(),
          enable_go_to_repo: boolean(),
          go_to_repo_top_modules: [module()],
          repo_url: String.t(),
          git_sha: String.t(),
          discord_client: DiscoLog.Discord.API.t(),
          in_app_modules: [module()]
        }

  @type supervisor_name() :: atom()

  @doc """
  Reads and validates config from global application configuration
  """
  @spec read!() :: t()
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
  @spec validate!(options :: keyword() | map()) :: t()
  def validate!(options) do
    {:ok, config} = validate(options)
    config
  end

  @doc """
  Validates configuration against the schema
  """
  @spec validate(options :: keyword() | map()) ::
          {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(%{discord_client: _} = config) do
    config
    |> Map.delete(:discord_client)
    |> validate()
  end

  def validate(raw_options) do
    with {:ok, validated} <- NimbleOptions.validate(raw_options, @compiled_schema),
         {:ok, validated} <- validate_optional_dependencies(validated) do
      config =
        validated
        |> Map.new()
        |> then(fn config ->
          client = config.discord_client_module.client(config.token)
          Map.put(config, :discord_client, %{client | log?: config.enable_discord_log})
        end)
        |> then(fn config ->
          modules = Application.spec(config.otp_app, :modules) || []
          Map.put(config, :in_app_modules, modules)
        end)

      {:ok, config}
    end
  end

  if Code.ensure_loaded?(Mint.WebSocket) do
    defp validate_optional_dependencies(validated), do: {:ok, validated}
  else
    defp validate_optional_dependencies(validated) do
      if value = validated[:enable_presence] do
        {:error,
         %NimbleOptions.ValidationError{
           message: "optional mint_web_socket dependency is missing",
           key: :enable_presence,
           value: value
         }}
      else
        {:ok, validated}
      end
    end
  end
end
