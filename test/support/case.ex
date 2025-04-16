defmodule DiscoLog.Test.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  @config [
    otp_app: :disco_log,
    token: "mytoken",
    guild_id: "guild_id",
    category_id: "category_id",
    occurrences_channel_id: "occurrences_channel_id",
    info_channel_id: "info_channel_id",
    error_channel_id: "error_channel_id",
    discord_client_module: DiscoLog.Discord.API.Mock,
    enable_presence: false,
    enable_go_to_repo: true,
    go_to_repo_top_modules: ["DiscoLog"],
    repo_url: "https://github.com/mrdotb/disco-log/blob",
    git_sha: "main"
  ]

  using do
    quote do
      import DiscoLog.Test.Case

      setup tags do
        if tags[:async] do
          Mox.stub_with(DiscoLog.Discord.API.Mock, DiscoLog.Discord.API.Stub)
        end

        :ok
      end
    end
  end

  @doc """
  Builds an error produced by the given function.
  """
  def build_error(fun) do
    fun.()
  rescue
    exception ->
      DiscoLog.Error.new(exception, __STACKTRACE__, %{}, DiscoLog.Config.validate!(@config))
  catch
    kind, reason ->
      DiscoLog.Error.new({kind, reason}, __STACKTRACE__, %{}, DiscoLog.Config.validate!(@config))
  end

  @doc """
  Reports the error produced by the given function.
  """
  def report_error(fun) do
    occurrence =
      try do
        fun.()
      rescue
        exception ->
          DiscoLog.report(exception, __STACKTRACE__)
      catch
        kind, reason ->
          DiscoLog.report({kind, reason}, __STACKTRACE__)
      end

    occurrence
  end

  @doc """
  Asserts that the given telemetry event is attached to the given module.
  """
  def event_attached?(event, module) do
    event
    |> :telemetry.list_handlers()
    |> Enum.any?(fn %{id: id} -> id == module end)
  end

  @doc """
  Starts DiscoLog supervisor under test supervision tree and makes sure DiscoLog.Storage async init completes successfully with a stubbed response.
  """
  def setup_supervisor(context) do
    config =
      [
        otp_app: :foo,
        token: "mytoken",
        guild_id: "guild_id",
        category_id: "category_id",
        occurrences_channel_id: "occurrences_channel_id",
        info_channel_id: "info_channel_id",
        error_channel_id: "error_channel_id",
        discord_client_module: DiscoLog.Discord.API.Mock,
        enable_presence: false
      ]
      |> Keyword.merge(Map.fetch!(context, :config))
      |> DiscoLog.Config.validate!()

    Mox.stub(DiscoLog.WebsocketClient.Mock, :connect, fn _, _, _ ->
      {:ok, struct(DiscoLog.WebsocketClient, %{})}
    end)

    {:ok, _pid} = start_supervised({DiscoLog.Supervisor, config})

    # Wait until async init is completed
    [{storage_pid, _}] =
      Registry.lookup(DiscoLog.Registry.registry_name(config.supervisor_name), DiscoLog.Storage)

    :sys.get_status(storage_pid)

    %{config: config}
  end

  @doc """
  Attach individual test logger handler with ownership filter
  """
  def setup_logger_handler(%{test: test, config: config} = context) do
    big_config_override = Map.take(context, [:handle_otp_reports, :handle_sasl_reports])

    {context, on_exit} =
      LoggerHandlerKit.Arrange.add_handler(
        test,
        DiscoLog.LoggerHandler,
        config,
        big_config_override
      )

    on_exit(on_exit)
    context
  end
end
