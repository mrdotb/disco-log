defmodule DiscoLog.Test.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  @config DiscoLog.Config.validate!(
            otp_app: :disco_log,
            token: "mytoken",
            guild_id: "guild_id",
            category_id: "category_id",
            occurrences_channel_id: "occurences_channel_id",
            info_channel_id: "info_channel_id",
            error_channel_id: "error_channel_id",
            discord: DiscoLog.DiscordMock,
            enable_presence: false,
            enable_go_to_repo: true,
            go_to_repo_top_modules: ["DiscoLog"],
            repo_url: "https://github.com/mrdotb/disco-log/blob",
            git_sha: "main"
          )

  using do
    quote do
      import DiscoLog.Test.Case
    end
  end

  @doc """
  Builds an error produced by the given function.
  """
  def build_error(fun) do
    fun.()
  rescue
    exception ->
      DiscoLog.Error.new(exception, __STACKTRACE__, %{}, @config)
  catch
    kind, reason ->
      DiscoLog.Error.new({kind, reason}, __STACKTRACE__, %{}, @config)
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
        occurrences_channel_id: "occurences_channel_id",
        info_channel_id: "info_channel_id",
        error_channel_id: "error_channel_id",
        discord: DiscoLog.DiscordMock,
        enable_presence: false
      ]
      |> Keyword.merge(Map.fetch!(context, :config))
      |> DiscoLog.Config.validate!()

    Mox.stub(DiscoLog.WebsocketClient.Mock, :connect, fn _, _, _ ->
      {:ok, struct(DiscoLog.WebsocketClient, %{})}
    end)

    DiscoLog.DiscordMock
    |> Mox.stub(:get_gateway, fn _config -> {:ok, "wss://gateway.discord.gg"} end)
    |> Mox.stub(:list_occurrence_threads, fn _, _ -> [] end)
    |> Mox.stub(:list_tags, fn _, _ -> %{} end)

    {:ok, _pid} = start_supervised({DiscoLog.Supervisor, config})

    # Wait until async init is completed
    [{storage_pid, _}] =
      Registry.lookup(DiscoLog.Registry.registry_name(config.supervisor_name), DiscoLog.Storage)

    :sys.get_status(storage_pid)

    %{config: config}
  end

  @doc """
  Attaches a dedicated logger handler for a test which will skip all events that don't originate in the test.
  """
  def attach_logger_handler(%{config: config, test: test}) do
    :logger.add_handler(test, DiscoLog.LoggerHandler, %{
      config: config,
      filters: [
        filter_only_self:
          {fn event, test_pid ->
             # Some test spawn new processes that the handler will be invoked, so `self()` is not necessarily the same as `test_pid`.
             # To identify if this is the case we piggyback on Mox ownership mechanism, assuming that if test spawned a process,
             # it also allowed the process to call DiscordMock either explicitely or through $callers
             callers = Process.get(:"$callers") || []

             {:ok, owner_pid} =
               NimbleOwnership.fetch_owner(
                 {:global, Mox.Server},
                 [self() | callers],
                 DiscoLog.DiscordMock
               )

             if owner_pid == test_pid, do: event, else: :stop
           end, self()}
      ]
    })

    on_exit(fn -> :logger.remove_handler(test) end)

    :ok
  end
end
