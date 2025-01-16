defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: true

  import Mox
  require Logger
  alias DiscoLog.DiscordMock

  @moduletag config: [supervisor_name: __MODULE__]

  setup :setup_supervisor
  setup :attach_logger_handler
  setup :verify_on_exit!

  test "skips logs that are not info or lower than error" do
    # The test can't fail but there will be :remove_failing_handler error
    Logger.debug("Debug message")
    Logger.warning("Warning message")
  end

  describe "info level" do
    test "info log string type" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.info("Info message")

      assert_receive {"info_channel_id", "Info message", %{}}
    end

    test "info log report type map" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.info(%{message: "Info message"})

      assert_receive {"info_channel_id", %{message: "Info message"}, %{}}
    end

    test "info log report type keyword" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.info(message: "Info message")

      assert_receive {"info_channel_id", %{message: "Info message"}, %{}}
    end

    test "info log report type struct" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.info(%Foo{})

      assert_receive {"info_channel_id", %{__struct__: "Elixir.Foo", bar: nil}, %{}}
    end

    test "info log erlang format" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      :logger.info("Hello ~s", ["world"])

      assert_receive {"info_channel_id", "Hello world", %{}}
    end
  end

  describe "error level" do
    test "error log string type" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.error("Error message")

      assert_receive {"error_channel_id", "Error message", %{}}
    end

    test "error log report type struct" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.error(%Foo{})

      assert_receive {"error_channel_id", %{__struct__: "Elixir.Foo", bar: nil}, %{}}
    end

    test "error log report type map" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.error(%{message: "Error message"})

      assert_receive {"error_channel_id", %{message: "Error message"}, %{}}
    end

    test "error log report type keyword" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.error(message: "Error message")

      assert_receive {"error_channel_id", [message: "Error message"], %{}}
    end

    test "error log erlang format" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      :logger.error("Hello ~s", ["world"])

      assert_receive {"error_channel_id", "Hello world", %{}}
    end

    test "error log IO data" do
      pid = self()

      expect(DiscordMock, :create_message, fn _config, channel_id, message, metadata ->
        send(pid, {channel_id, message, metadata})
      end)

      Logger.error(["Hello", " ", "world"])

      assert_receive {"error_channel_id", "Hello world", %{}}
    end

    test "a logged raised exception is" do
      pid = self()
      ref = make_ref()

      expect(DiscordMock, :create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      Task.start(fn ->
        raise "Unique Error"
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(RuntimeError)
      assert error.reason == "Unique Error"
    end

    test "badarith error" do
      pid = self()
      ref = make_ref()

      expect(DiscordMock, :create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      Task.start(fn ->
        1 + to_string(1)
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(ArithmeticError)
      assert error.reason == "bad argument in arithmetic expression"
    end

    test "undefined function errors" do
      pid = self()
      ref = make_ref()

      expect(DiscordMock, :create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      # This function does not exist and will raise when called
      {m, f, a} = {DiscoLog, :invalid_fun, []}

      Task.start(fn ->
        apply(m, f, a)
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(UndefinedFunctionError)
      assert error.reason =~ "is undefined or private"
    end

    test "throws" do
      pid = self()
      ref = make_ref()

      expect(DiscordMock, :create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      Task.start(fn ->
        throw("This is a test")
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver"
      assert error.reason =~ ":nocatch"
    end
  end

  describe "with a crashing GenServer" do
    setup do
      %{test_genserver: start_supervised!(DiscoLog.TestGenServer, restart: :temporary)}
    end

    test "a GenServer raising an error is reported",
         %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      run_and_catch_exit(test_genserver, fn -> Keyword.fetch!([], :foo) end)

      assert_receive {^ref, error}
      assert error.kind == to_string(KeyError)
      assert error.reason == "key :foo not found in: []"
    end

    test "a GenServer throw is reported", %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      run_and_catch_exit(test_genserver, fn ->
        throw(:testing_throw)
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver"
      assert error.reason =~ "testing_throw"
      assert error.source_line == "nofile"
      assert error.source_function == "nofunction"
      assert error.context.extra_info_from_message.last_message =~ "GenServer throw is reported"
    end

    test "abnormal GenServer exit is reported", %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, :bad_exit, :no_state}
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver"
      assert error.reason =~ "bad_exit"
      assert error.source_line == "nofile"
      assert error.source_function == "nofunction"
      assert error.context.extra_info_from_message.last_message =~ "GenServer exit is reported"
    end

    test "an exit while calling another GenServer is reported nicely",
         %{test_genserver: test_genserver} do
      test_pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(test_pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(test_pid, {ref, error})
      end)

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
         %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

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
         %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      run_and_catch_exit(test_genserver, fn ->
        raise "Hello World"
      end)

      assert_receive {^ref, error}
      assert error.kind == to_string(RuntimeError)
      assert error.reason == "Hello World"
    end

    test "an exit with a struct is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, %Mint.HTTP1{}, :no_state}
      end)

      assert_receive {^ref, error}
      assert error.kind == "genserver"
      assert error.reason =~ "** (stop) %Mint.HTTP1"
    end

    @tag config: [enable_presence: true]
    test "GenServer crash should not crash the logger handler", %{
      config: config,
      test_genserver: test_genserver
    } do
      pid = self()
      ref = make_ref()

      DiscoLog.WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn _client, {:ssl, :fake_ssl_closed} ->
        {:error, nil, %Mint.TransportError{reason: :closed}}
      end)
      |> stub(:send_frame, fn _, _ -> {:error, :socket_closed_at_this_point} end)

      DiscordMock
      |> allow(pid, test_genserver)
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

      pid =
        DiscoLog.Registry.via(config.supervisor_name, DiscoLog.Presence) |> GenServer.whereis()

      send(pid, {:ssl, :fake_ssl_closed})

      assert_receive {^ref, error}
      assert error.kind == "genserver"

      assert error.reason =~
               "** (stop) {:error, nil, %Mint.TransportError{reason: :closed}}"

      assert error.context.extra_info_from_genserver.message =~
               "GenServer %{} terminating: ** (stop)"
    end

    test "GenServer timeout is reported", %{test_genserver: test_genserver} do
      pid = self()
      ref = make_ref()

      DiscordMock
      |> expect(:create_occurrence_thread, fn _config, error ->
        send(pid, {ref, error})
      end)

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
  end

  defp run_and_catch_exit(test_genserver_pid, fun) do
    catch_exit(DiscoLog.TestGenServer.run(test_genserver_pid, fun))
  end
end
