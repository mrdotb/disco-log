defmodule DiscoLog.SaslTest do
  # This can't be async because we restart logger application
  use DiscoLog.Test.Case, async: false

  import Mox
  require Logger
  alias DiscoLog.DiscordMock

  @moduletag config: [supervisor_name: __MODULE__]

  setup_all do
    Application.stop(:logger)
    Application.put_env(:logger, :handle_sasl_reports, true)
    Application.start(:logger)

    on_exit(fn ->
      Application.stop(:logger)
      Application.put_env(:logger, :handle_sasl_reports, false)
      Application.start(:logger)
    end)
  end

  setup :setup_supervisor

  setup %{config: config} do
    :logger.add_handler(__MODULE__, DiscoLog.LoggerHandler, %{config: config})

    on_exit(fn -> :logger.remove_handler(__MODULE__) end)
  end

  setup :set_mox_global
  setup :verify_on_exit!

  test "reports crashes on c:GenServer.init/1" do
    pid = self()
    ref = make_ref()

    DiscordMock
    |> expect(:create_occurrence_thread, fn _config, error ->
      send(pid, {ref, error})
    end)

    defmodule CrashingGenServerInInit do
      use GenServer
      def init(_args), do: raise("oops")
    end

    assert {:error, _reason_and_stacktrace} = GenServer.start(CrashingGenServerInInit, :no_arg)

    # Pattern match the type cause we receive some other garbage messages
    assert_receive {^ref, %DiscoLog.Error{} = error}
    assert error.kind == to_string(RuntimeError)
    assert error.reason == "oops"
  end
end
