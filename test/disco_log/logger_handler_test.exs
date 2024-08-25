defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: false

  require Logger

  setup :register_before_send

  test "skips logs that are not info or lower than error", %{sender_ref: ref} do
    Logger.debug("Debug message")
    Logger.warning("Warning message")

    refute_receive {^ref, _error}
  end

  describe "info level" do
    test "info log string type", %{sender_ref: ref} do
      Logger.info("Info message")

      assert_receive {^ref, {"Info message", %{}}}
    end

    test "info log report type", %{sender_ref: ref} do
      Logger.info(%{message: "Info message"})

      assert_receive {^ref, {%{message: "Info message"}, %{}}}
    end

    test "info log erlang format", %{sender_ref: ref} do
      :logger.info("Hello ~s", ["world"])

      assert_receive {^ref, {"Hello world", %{}}}
    end
  end

  describe "error level" do
    test "error log string type", %{sender_ref: ref} do
      Logger.error("Error message")
      assert_receive {^ref, {"Error message", %{}}}
    end

    test "error log report type", %{sender_ref: ref} do
      Logger.error(%{message: "Error message"})

      assert_receive {^ref, {%{message: "Error message"}, %{}}}
    end

    test "error log erlang format", %{sender_ref: ref} do
      :logger.error("Hello ~s", ["world"])

      assert_receive {^ref, {"Hello world", %{}}}
    end

    test "a logged raised exception is", %{sender_ref: ref} do
      Task.start(fn ->
        raise "Unique Error"
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(RuntimeError)
      assert error.reason == "Unique Error"
    end

    test "badarith error", %{sender_ref: ref} do
      Task.start(fn ->
        1 + to_string(1)
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(ArithmeticError)
      assert error.reason == "bad argument in arithmetic expression"
    end

    test "undefined function errors", %{sender_ref: ref} do
      # This function does not exist and will raise when called
      {m, f, a} = {DiscoLog, :invalid_fun, []}

      Task.start(fn ->
        apply(m, f, a)
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(UndefinedFunctionError)
      assert error.reason =~ "is undefined or private"
    end

    test "throws", %{sender_ref: ref} do
      Task.start(fn ->
        throw("This is a test")
      end)

      assert_receive {^ref, error}
      assert error.kind == "nocatch"
      assert error.reason == "This is a test"
    end
  end

  describe "with a crashing GenServer" do
    setup do
      %{test_genserver: start_supervised!(DiscoLog.TestGenServer, restart: :temporary)}
    end

    test "a GenServer raising an error is reported",
         %{sender_ref: ref, test_genserver: test_genserver} do
      run_and_catch_exit(test_genserver, fn -> Keyword.fetch!([], :foo) end)

      assert_receive {^ref, error}
      assert error.kind == to_string(KeyError)
      assert error.reason == "key :foo not found in: []"
    end

    test "a GenServer throw is reported", %{sender_ref: ref, test_genserver: test_genserver} do
      run_and_catch_exit(test_genserver, fn ->
        throw(:testing_throw)
      end)

      assert_receive {^ref, error}
      assert error.kind == "bad_return_value"
      assert error.reason == "testing_throw"
      assert error.source_line == "nofile"
      assert error.source_function == "nofunction"
      assert error.context.extra_info_from_message.last_message =~ "GenServer throw is reported"
    end

    test "abnormal GenServer exit is reported", %{sender_ref: ref, test_genserver: test_genserver} do
      run_and_catch_exit(test_genserver, fn ->
        {:stop, :bad_exit, :no_state}
      end)

      assert_receive {^ref, error}
      assert error.kind == "exit"
      assert error.reason == "bad_exit"
      assert error.source_line == "nofile"
      assert error.source_function == "nofunction"
      assert error.context.extra_info_from_message.last_message =~ "GenServer exit is reported"
    end

    test "an exit while calling another GenServer is reported nicely",
         %{sender_ref: ref, test_genserver: test_genserver} do
      # Get a PID and make sure it's done before using it.
      {pid, monitor_ref} = spawn_monitor(fn -> :ok end)
      assert_receive {:DOWN, ^monitor_ref, _, _, _}

      run_and_catch_exit(test_genserver, fn ->
        GenServer.call(pid, :ping)
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver_call"
      assert error.reason == "noproc"

      assert error.context.extra_reason =~
               "** (EXIT) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application isn't started"
    end

    test "a timeout while calling another GenServer is reported nicely",
         %{sender_ref: ref, test_genserver: test_genserver} do
      {:ok, agent} = Agent.start_link(fn -> nil end)

      run_and_catch_exit(test_genserver, fn ->
        Agent.get(agent, & &1, 0)
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver_call"
      assert error.reason == "timeout"
      assert error.context.extra_reason =~ "** (EXIT) time out"
    end

    test "bad function call causing GenServer crash is reported",
         %{sender_ref: ref, test_genserver: test_genserver} do
      run_and_catch_exit(test_genserver, fn ->
        invalid_function()
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(FunctionClauseError)
      assert error.reason == "no function clause matching in NaiveDateTime.from_erl/3"
    end

    test "GenServer timeout is reported", %{sender_ref: ref, test_genserver: test_genserver} do
      Task.start(fn ->
        DiscoLog.TestGenServer.run(
          test_genserver,
          fn -> Process.sleep(:infinity) end,
          _timeout = 0
        )
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver_call"
      assert error.reason == "timeout"
      assert error.context.extra_reason =~ "exited in: GenServer.call("
      assert error.context.extra_reason =~ "** (EXIT) time out"
    end

    test "reports crashes on c:GenServer.init/1", %{sender_ref: ref} do
      enable_sasl_reports()

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

  defp register_before_send(_context) do
    pid = self()
    ref = make_ref()

    Application.put_env(:disco_log, :before_send, fn
      {message, metadata} ->
        send(pid, {ref, {message, metadata}})
        false

      error ->
        send(pid, {ref, error})
        false
    end)

    %{sender_ref: ref}
  end

  defp run_and_catch_exit(test_genserver_pid, fun) do
    catch_exit(DiscoLog.TestGenServer.run(test_genserver_pid, fun))
  end

  defp invalid_function do
    NaiveDateTime.from_erl({}, {}, {})
  end

  defp enable_sasl_reports do
    Application.stop(:logger)
    Application.put_env(:logger, :handle_sasl_reports, true)
    Application.start(:logger)

    on_exit(fn ->
      Application.stop(:logger)
      Application.put_env(:logger, :handle_sasl_reports, false)
      Application.start(:logger)
    end)
  end
end
