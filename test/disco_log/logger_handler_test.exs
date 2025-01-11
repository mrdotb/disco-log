defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: true

  import Mox
  require Logger
  alias DiscoLog.Discord.API

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

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info("Info message")

      assert_receive [{:path_params, [channel_id: "info_channel_id"]}, {:form_multipart, body}]
      assert %{payload_json: %{content: "Info message"}} = decode_body(body)
    end

    test "info log report type map" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(%{message: "Info message"})

      assert_receive [{:path_params, [channel_id: "info_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{message: "Info message"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "info log report type keyword" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(message: "Info message")

      assert_receive [{:path_params, [channel_id: "info_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{message: "Info message"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "info log report type struct" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.info(%Foo{})

      assert_receive [{:path_params, [channel_id: "info_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{__struct__: "Elixir.Foo", bar: "nil"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "info log erlang format" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      :logger.info("Hello ~s", ["world"])

      assert_receive [{:path_params, [channel_id: "info_channel_id"]}, {:form_multipart, body}]
      assert %{payload_json: %{content: "Hello world"}} = decode_body(body)
    end
  end

  describe "error level" do
    test "error log string type" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error("Error message")

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]
      assert %{payload_json: %{content: "Error message"}} = decode_body(body)
    end

    test "error log report type struct" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%Foo{})

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{__struct__: "Elixir.Foo", bar: "nil"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "error log report type map" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%{message: "Error message"})

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{message: "Error message"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "error log report type keyword" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(message: "Error message")

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]

      assert %{message: {%{message: "Error message"}, [filename: "message.json"]}} =
               decode_body(body)
    end

    test "error log erlang format" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      :logger.error("Hello ~s", ["world"])

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]
      assert %{payload_json: %{content: "Hello world"}} = decode_body(body)
    end

    test "error log IO data" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(["Hello", " ", "world"])

      assert_receive [{:path_params, [channel_id: "error_channel_id"]}, {:form_multipart, body}]
      assert %{payload_json: %{content: "Hello world"}} = decode_body(body)
    end

    test "a logged raised exception is" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        raise "Unique Error"
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "Unique Error"
      assert thread_name =~ "Elixir.RuntimeError"
    end

    test "badarith error" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        1 + to_string(1)
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "bad argument in arithmetic expression"
      assert thread_name =~ "Elixir.ArithmeticError"
    end

    test "undefined function errors" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      # This function does not exist and will raise when called
      {m, f, a} = {DiscoLog, :invalid_fun, []}

      Task.start(fn ->
        apply(m, f, a)
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "function DiscoLog.invalid_fun/0 is undefined or private"
      assert thread_name =~ "Elixir.UndefinedFunctionError"
    end

    test "throws" do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        throw("This is a test")
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "{:nocatch, \"This is a test\"}"
      assert thread_name =~ "genserver"
    end
  end

  describe "with a crashing GenServer" do
    setup do
      %{test_genserver: start_supervised!(DiscoLog.TestGenServer, restart: :temporary)}
    end

    test "a GenServer raising an error is reported",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn -> Keyword.fetch!([], :foo) end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "key :foo not found in: []"
      assert thread_name =~ "Elixir.KeyError"
    end

    test "a GenServer throw is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        throw(:testing_throw)
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "** (stop) bad return value: :testing_throw"
      assert message =~ "nofile"
      assert message =~ "nofunction"
      assert thread_name =~ "genserver"
    end

    test "abnormal GenServer exit is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, :bad_exit, :no_state}
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "** (stop) :bad_exit"
      assert message =~ "nofile"
      assert message =~ "nofunction"
      assert thread_name =~ "genserver"
    end

    test "an exit while calling another GenServer is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      # Get a PID and make sure it's done before using it.
      {pid, monitor_ref} = spawn_monitor(fn -> :ok end)
      assert_receive {:DOWN, ^monitor_ref, _, _, _}

      run_and_catch_exit(test_genserver, fn ->
        GenServer.call(pid, :ping)
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               },
               context: {%{extra_reason: extra_reason}, _}
             } = decode_body(body)

      assert message =~ "genserver_call"
      assert message =~ "noproc"
      assert thread_name =~ "genserver_call"

      assert extra_reason =~
               "** (EXIT) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application isn't started"
    end

    test "a timeout while calling another GenServer is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      {:ok, agent} = Agent.start_link(fn -> nil end)

      run_and_catch_exit(test_genserver, fn ->
        Agent.get(agent, & &1, 0)
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               },
               context: {%{extra_reason: extra_reason}, _}
             } = decode_body(body)

      assert message =~ "genserver_call"
      assert message =~ "timeout"
      assert thread_name =~ "genserver_call"
      assert extra_reason =~ "** (EXIT) time out"
    end

    test "bad function call causing GenServer crash is reported",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        raise "Hello World"
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "Hello World"
      assert thread_name =~ "Elixir.RuntimeError"
    end

    test "an exit with a struct is reported nicely",
         %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      run_and_catch_exit(test_genserver, fn ->
        {:stop, %Mint.HTTP1{}, :no_state}
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               }
             } = decode_body(body)

      assert message =~ "** (stop) %Mint.HTTP1{"
      assert thread_name =~ "genserver"
    end

    @tag config: [enable_presence: true]
    test "GenServer crash should not crash the logger handler", %{
      config: config,
      test_genserver: test_genserver
    } do
      pid = self()
      ref1 = make_ref()
      ref2 = make_ref()

      DiscoLog.WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn _client, {:ssl, :fake_ssl_closed} ->
        {:error, nil, %Mint.TransportError{reason: :closed}}
      end)

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, 2, fn
        client, method, "/channels/:channel_id/threads" = url, opts ->
          send(pid, {ref1, opts})
          API.Stub.request(client, method, url, opts)

        # Presence will crash and restart, so we need to have gateway stubbed
        client, method, "/gateway/bot" = url, opts ->
          send(pid, {ref2, opts})
          API.Stub.request(client, method, url, opts)
      end)

      pid =
        DiscoLog.Registry.via(config.supervisor_name, DiscoLog.Presence) |> GenServer.whereis()

      send(pid, {:ssl, :fake_ssl_closed})

      # Wait until Presence complete the crash to avoid race conditions
      assert_receive {^ref2, _}

      assert_receive {^ref1,
                      [
                        {:path_params, [channel_id: "occurrences_channel_id"]},
                        {:form_multipart, body}
                      ]}

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               },
               context: {%{extra_info_from_genserver: %{message: extra_message}}, _}
             } = decode_body(body)

      assert message =~ "** (stop) {:error, nil, %Mint.TransportError{reason: :closed}}"
      assert thread_name =~ "genserver"

      assert extra_message =~
               "GenServer %{} terminating: ** (stop) {:error, nil, %Mint.TransportError{reason: :closed}}"
    end

    test "GenServer timeout is reported", %{test_genserver: test_genserver} do
      pid = self()

      API.Mock
      |> allow(pid, test_genserver)
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Task.start(fn ->
        DiscoLog.TestGenServer.run(
          test_genserver,
          fn -> Process.sleep(:infinity) end,
          _timeout = 0
        )
      end)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, body}
      ]

      assert %{
               payload_json: %{
                 applied_tags: [],
                 message: %{content: message},
                 name: thread_name
               },
               context: {%{extra_reason: extra_reason}, _}
             } = decode_body(body)

      assert message =~ "timeout"
      assert thread_name =~ "genserver_call"
      assert extra_reason =~ "exited in: GenServer.call("
    end
  end

  defp run_and_catch_exit(test_genserver_pid, fun) do
    catch_exit(DiscoLog.TestGenServer.run(test_genserver_pid, fun))
  end

  defp decode_body(body) do
    Map.new(body, fn
      {k, {content, file}} -> {k, {maybe_decode(content), file}}
      {k, v} -> {k, maybe_decode(v)}
    end)
  end

  defp maybe_decode(binary) do
    case Jason.decode(binary, keys: :atoms) do
      {:ok, decoded} -> decoded
      {:error, _} -> binary
    end
  end
end
