defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: true

  import Mox
  require Logger
  alias DiscoLog.Discord.API

  @moduletag config: [supervisor_name: __MODULE__]

  setup_all {LoggerHandlerKit.Arrange, :ensure_per_handler_translation}

  setup :setup_supervisor
  setup :setup_logger_handler
  setup :verify_on_exit!

  describe "info level" do
    test "string", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "charlist", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.charlist_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "chardata", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.chardata_message(:improper)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "map report", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.map_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "%{hello: \"world\"}"}]} = body
    end

    test "keyword report", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.keyword_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "[hello: \"world\"]"}]} = body
    end

    test "struct report", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.struct_report()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               components: [
                 %{type: 10, content: "%LoggerHandlerKit.FakeStruct{hello: \"world\"}"}
               ]
             } = body
    end

    test "erlang io format", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.io_format()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    @tag config: [metadata: [:extra]]
    test "metadata is attached if configured", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.metadata(extra: "Hello")
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               components: [
                 %{type: 10, content: "Hello World"},
                 %{type: 10, content: "```elixir\n%{extra: \"Hello\"}\n```"}
               ]
             } = body
    end

    @tag config: [metadata: [:extra]]
    test "context is not attached for log messages", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.metadata(extra: "Hello")
      DiscoLog.Context.set(:foo, "bar")
      LoggerHandlerKit.Act.string_message()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "info_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               components: [
                 %{type: 10, content: "Hello World"},
                 %{type: 10, content: "```elixir\n%{extra: \"Hello\"}\n```"}
               ]
             } = body
    end
  end

  describe "error level" do
    test "string", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error("Error message")
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Error message"}]} = body
    end

    test "charlist", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(~c"Hello World")
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "chardata", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error([?H, ["ello", []], 32 | ~c"World"])
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "map", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%{message: "Error message"})
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "%{message: \"Error message\"}"}]} = body
    end

    test "keyword", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(message: "Error message")
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "[message: \"Error message\"]"}]} = body
    end

    test "struct", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      Logger.error(%LoggerHandlerKit.FakeStruct{hello: "world"})
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               components: [
                 %{type: 10, content: "%LoggerHandlerKit.FakeStruct{hello: \"world\"}"}
               ]
             } = body
    end

    test "erlang io format", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      :logger.error("Hello ~s", ["World"])
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "error_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{components: [%{type: 10, content: "Hello World"}]} = body
    end

    test "task error exception", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.task_error(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (RuntimeError) oops"
             } = body

      assert message =~ "Task.Supervised.invoke_mfa"
    end

    test "task error undefined", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.task_error(:undefined)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name:
                 <<_::binary-size(7)>> <>
                   "** (UndefinedFunctionError) function :module_does_not_exist.undef/0 is undefined …"
             } = body

      assert message =~ "function :module_does_not_exist.undef/0 is undefined"
    end

    test "task error throw", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.task_error(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (throw) \"catch!\""
             } = body

      assert message =~ "LoggerHandlerKit.Act.task_error"
    end

    test "task error exit", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.task_error(:exit)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) \"i quit\""
             } = body

      assert message =~ "LoggerHandlerKit.Act.task_error"
    end

    test "genserver crash exception", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.genserver_crash(:exception)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (RuntimeError) oops"
             } = body

      assert message =~ "LoggerHandlerKit.Act.genserver_crash"
    end

    test "genserver crash throw", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.genserver_crash(:throw)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) bad return value: \"catch!\""
             } = body

      assert message =~ "GenServer "
      assert message =~ "terminating"
    end

    test "genserver crash abnormal exit", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      try do
        {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
        GenServer.call(pid, {:run, fn -> {:stop, :bad_exit, :no_state} end})
      catch
        :exit, {:bad_exit, _} -> :ok
      end

      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) :bad_exit"
             } = body

      assert message =~ "GenServer "
      assert message =~ "terminating"
    end

    test "genserver crash while calling another process", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      # Get a PID and make sure it's done before using it.
      {dead_pid, monitor_ref} = spawn_monitor(fn -> :ok end)
      assert_receive {:DOWN, ^monitor_ref, _, _, _}

      try do
        {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
        GenServer.call(pid, {:run, fn -> GenServer.call(dead_pid, :ping) end})
      catch
        :exit, {{:noproc, _}, _} -> :ok
      end

      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) exited in …"
             } = body

      assert message =~
               "** (EXIT) no process: the process is not alive or there's no process currently associated with the given name"
    end

    test "genserver crash due to timeout calling another genserver", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      {:ok, agent} = Agent.start_link(fn -> nil end)

      try do
        {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)
        GenServer.call(pid, {:run, fn -> Agent.get(agent, & &1, 0) end})
      catch
        :exit, {{:timeout, _}, _} -> :ok
      end

      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) exited in …"
             } = body

      assert message =~ "GenServer"
      assert message =~ "terminating"
    end

    test "genserver crash exit with a struct", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.genserver_crash(:exit_with_struct)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _},
                   %{content: message}
                 ]
               },
               name:
                 <<_::binary-size(7)>> <>
                   "** (exit) %LoggerHandlerKit.FakeStruct{hello: \"world\"}" <> _
             } = body

      assert message =~ "GenServer"
      assert message =~ "terminating"
    end

    @tag config: [enable_presence: true]
    test "GenServer crash should not crash the logger handler", %{
      handler_ref: handler_ref,
      config: config
    } do
      pid = self()
      ref1 = make_ref()
      ref2 = make_ref()

      DiscoLog.WebsocketClient.Mock
      |> expect(:boil_message_to_frames, fn _client, {:ssl, :fake_ssl_closed} ->
        {:error, nil, %Mint.TransportError{reason: :closed}}
      end)

      expect(API.Mock, :request, 2, fn
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

      LoggerHandlerKit.Assert.assert_logged(handler_ref)

      # Wait until Presence complete the crash to avoid race conditions
      assert_receive {^ref2, _}

      assert_receive {^ref1,
                      [
                        {:path_params, [channel_id: "occurrences_channel_id"]},
                        {:form_multipart, [payload_json: body]}
                      ]}

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name:
                 <<_::binary-size(7)>> <> "** (exit) {:error, nil, %Mint.TransportError{reason …"
             } = body

      assert message =~ "GenServer {DiscoLog.Registry, DiscoLog.Presence} terminating"
    end

    test "GenServer timeout is reported", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)

      Task.start(fn ->
        GenServer.call(pid, {:run, fn -> Process.sleep(:infinity) end}, 0)
      end)

      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   %{content: _message},
                   %{content: message}
                 ]
               },
               name: <<_::binary-size(7)>> <> "** (exit) exited in …"
             } = body

      assert message =~ "timeout"
    end

    @tag config: [metadata: [:extra]]
    test "both configured metadata and context attached to the occurrence", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      try do
        {:ok, pid} = LoggerHandlerKit.GenServer.start(nil)

        GenServer.call(
          pid,
          {:run,
           fn ->
             Logger.metadata(extra: "hello")
             DiscoLog.Context.set(:foo, "bar")
             {:stop, :bad_exit, :no_state}
           end}
        )
      catch
        :exit, {:bad_exit, _} -> :ok
      end

      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: [],
               message: %{
                 components: [
                   _,
                   _,
                   %{type: 10, content: "```elixir\n%{extra: \"hello\", foo: \"bar\"}\n```"}
                 ]
               }
             } = body
    end
  end

  describe "sasl reports" do
    @describetag handle_sasl_reports: true

    test "reports crashed c:GenServer.init/1", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.genserver_init_crash()
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [{:path_params, [channel_id: "occurrences_channel_id"]} | _]
    end
  end
end
