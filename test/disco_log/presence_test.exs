defmodule DiscoLog.PresenceTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  alias DiscoLog.Presence
  alias DiscoLog.WebsocketClient
  alias DiscoLog.DiscordMock

  setup :verify_on_exit!

  setup_all do
    Registry.start_link(keys: :unique, name: __MODULE__.Registry)
    :ok
  end

  describe "start_link" do
    test "connects to gateway on startup" do
      expect(DiscordMock, :get_gateway, fn _config -> {:ok, "wss://foo.bar"} end)

      expect(WebsocketClient.Mock, :connect, fn host, port, path ->
        assert "foo.bar" = host
        assert 443 = port
        assert "/v=10&encoding=json" = path
        {:ok, %WebsocketClient{}}
      end)

      pid =
        start_link_supervised!(
          {Presence,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken"},
             discord: DiscordMock
           ]}
        )

      _ = :sys.get_status(pid)
    end
  end

  describe "Normal work" do
    setup do
      stub(DiscordMock, :get_gateway, fn _config -> {:ok, "wss://gateway.discord.gg"} end)
      client = %WebsocketClient{}
      stub(WebsocketClient.Mock, :connect, fn _, _, _ -> {:ok, client} end)

      pid =
        start_link_supervised!(
          {Presence,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken"},
             discord: DiscordMock,
             jitter: 1
           ]}
        )

      :sys.get_status(pid)

      %{client: client, pid: pid}
    end

    test "Connect: no immediate Hello event", %{pid: pid} do
      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_upgrade} ->
        {:ok, client, nil}
      end)

      send(pid, {:ssl, :fake_upgrade})
      :sys.get_status(pid)
    end

    test "Hello: sends Identify", %{pid: pid} do
      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_hello} ->
        msg = %{
          "op" => 10,
          "s" => 42,
          "d" => %{
            "heartbeat_interval" => 60_000
          }
        }

        {:ok, client, [text: Jason.encode!(msg)]}
      end)
      |> expect(:send_frame, fn %WebsocketClient{} = client, {:text, event} ->
        assert %{
                 "op" => 2,
                 "d" => %{
                   "token" => "mytoken",
                   "intents" => 0,
                   "presence?" => %{
                     "since" => nil,
                     "status" => "online",
                     "afk" => false
                   },
                   "properties" => %{
                     "os" => "BEAM",
                     "browser" => "DiscoLog",
                     "device" => "DiscoLog"
                   }
                 }
               } = Jason.decode!(event)

        {:ok, client}
      end)

      send(pid, {:ssl, :fake_hello})
      :sys.get_status(pid)
    end

    test "Hello: schedules first heartbeat at jitter * heartbeat_interval", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_hello} ->
        msg = %{
          "op" => 10,
          "s" => 42,
          "d" => %{
            "heartbeat_interval" => 0
          }
        }

        {:ok, client, [text: Jason.encode!(msg)]}
      end)
      |> expect(:send_frame, 2, fn
        %WebsocketClient{ref: nil} = client, _event ->
          {:ok, %{client | ref: 1}}

        %WebsocketClient{ref: 1} = client, {:text, event} ->
          assert %{
                   "op" => 1,
                   "d" => 42
                 } = Jason.decode!(event)

          send(test_pid, :heartbeat_completed)

          {:ok, client}
      end)

      send(pid, {:ssl, :fake_hello})
      assert_receive :heartbeat_completed
    end

    test "Heartbeat ACK: noop", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_ack} ->
        send(test_pid, :ack_handled)
        {:ok, client, [text: Jason.encode!(%{"op" => 11})]}
      end)

      send(pid, {:ssl, :fake_ack})
      assert_receive :ack_handled
    end

    test "Heartbeat: closes connection if no ACK received between regular heartbeats", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_hello} ->
        msg = %{
          "op" => 10,
          "s" => 42,
          "d" => %{
            "heartbeat_interval" => 60_000
          }
        }

        {:ok, client, [text: Jason.encode!(msg)]}
      end)
      |> expect(:send_frame, 3, fn
        client, {:text, _frame} ->
          {:ok, %{client | ref: 1}}

        client, {:close, 1008, "server missed ack"} ->
          send(test_pid, :close_sent)
          {:ok, client}
      end)

      send(pid, {:ssl, :fake_hello})
      send(pid, :heartbeat)
      send(pid, :heartbeat)
      assert_receive :close_sent
    end

    test "Heartbeat: responds to Heartbeat requests", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client,
                                           {:ssl, :fake_heartbeat_request} ->
        {:ok, client, [text: Jason.encode!(%{"op" => 1})]}
      end)
      |> expect(:send_frame, fn %WebsocketClient{} = client, {:text, event} ->
        assert %{"op" => 1} = Jason.decode!(event)
        send(test_pid, :heartbeat_sent)
        {:ok, client}
      end)

      send(pid, {:ssl, :fake_heartbeat_request})
      assert_receive :heartbeat_sent
    end

    test "Ready(Dispatch): noop", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client,
                                           {:ssl, :fake_ready_event} ->
        send(test_pid, :event_handled)
        {:ok, client, [text: Jason.encode!(%{"op" => 0, "s" => 43})]}
      end)

      send(pid, {:ssl, :fake_ready_event})
      assert_receive :event_handled
    end

    test "Other events: noop", %{pid: pid} do
      test_pid = self()

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn %WebsocketClient{} = client, {:ssl, :fake_event} ->
        send(test_pid, :event_handled)
        {:ok, client, [text: Jason.encode!(%{"op" => 7})]}
      end)

      send(pid, {:ssl, :fake_event})
      assert_receive :event_handled
    end
  end

  describe "Fail modes" do
    setup tags do
      stub(DiscordMock, :get_gateway, fn _config -> {:ok, "wss://gateway.discord.gg"} end)

      client =
        Map.merge(%{state: :open, websocket: %Mint.WebSocket{}}, Map.get(tags, :client, %{}))

      stub(WebsocketClient.Mock, :connect, fn _, _, _ ->
        {:ok, struct(WebsocketClient, client)}
      end)

      pid =
        start_supervised!(
          {Presence,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken"},
             discord: DiscordMock,
             jitter: 1
           ]}
        )

      :sys.get_status(pid)

      %{client: client, pid: pid}
    end

    test "exits on unexpected message", %{pid: pid} do
      ref = Process.monitor(pid)

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn _client, :unknown_message ->
        {:error, "BOOM"}
      end)
      |> expect(:send_frame, fn client, _ -> {:ok, client} end)

      send(pid, :unknown_message)
      assert_receive {:DOWN, ^ref, :process, ^pid, {:error, "BOOM"}}
    end

    test "tries to gracefully disconnect if connection is open", %{pid: pid} do
      ref = Process.monitor(pid)

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn _client, :unknown_message ->
        {:error, "BOOM"}
      end)
      |> expect(:send_frame, fn client, {:close, 1000, "graceful disconnect"} -> {:ok, client} end)

      send(pid, :unknown_message)
      assert_receive {:DOWN, ^ref, :process, ^pid, {:error, "BOOM"}}
    end

    test "does not disconnects if process exiting due to disconnect", %{pid: pid} do
      ref = Process.monitor(pid)

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn _client, {:ssl, :fake_closed} ->
        {:ok, :closed}
      end)

      send(pid, {:ssl, :fake_closed})
      assert_receive {:DOWN, ^ref, :process, ^pid, {:shutdown, :closed_by_client}}
    end

    test "shuts down if server closes connection", %{pid: pid} do
      ref = Process.monitor(pid)

      WebsocketClient.Mock
      |> expect(:boil_message_to_frame, fn client, {:ssl, :fake_server_closed} ->
        {:ok, client, [{:close, 1000, "reason"}]}
      end)
      |> expect(:send_frame, fn client, :close -> {:ok, client} end)
      |> expect(:close, fn client -> {:ok, client} end)

      send(pid, {:ssl, :fake_server_closed})
      assert_receive {:DOWN, ^ref, :process, ^pid, {:shutdown, {:closed_by_server, "reason"}}}
    end

    @tag client: %{state: nil, websocket: nil}
    test "shuts down if upgrade fails with HTTP status code", %{pid: pid} do
      ref = Process.monitor(pid)

      WebsocketClient.Mock
      |> expect(:connect, fn _, _, _ -> {:ok, %WebsocketClient{}} end)
      |> expect(:boil_message_to_frame, fn _client, {:ssl, :fake_upgrade} ->
        {:error, nil, %Mint.WebSocket.UpgradeFailureError{status_code: 520}}
      end)

      send(pid, {:ssl, :fake_upgrade})

      assert_receive {:DOWN, ^ref, :process, ^pid,
                      {:shutdown, %Mint.WebSocket.UpgradeFailureError{status_code: 520}}}
    end
  end
end
