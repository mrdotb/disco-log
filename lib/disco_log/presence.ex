defmodule DiscoLog.Presence do
  @moduledoc """
  A GenServer responsible for keeping the bot Online

  The presence server is started automatically as long as the `enable_presence`
  configuration flag is set.

  See the [standalone presence guide](standalone-presence.md) to learn how to
  use presence without the rest of DiscoLog
  """
  use GenServer

  alias DiscoLog.WebsocketClient
  alias DiscoLog.Discord

  defstruct [
    :bot_token,
    :discord_client,
    :presence_status,
    :registry,
    :websocket_client,
    :jitter,
    :heartbeat_interval,
    :sequence_number,
    :waiting_for_ack?
  ]

  def start_link(opts) do
    name =
      opts
      |> Keyword.fetch!(:supervisor_name)
      |> DiscoLog.Registry.via(__MODULE__)

    callers = Process.get(:"$callers", [])

    GenServer.start_link(__MODULE__, {opts, callers}, name: name)
  end

  @impl GenServer
  def init({opts, callers}) do
    state = %__MODULE__{
      bot_token: Keyword.fetch!(opts, :bot_token),
      discord_client: Keyword.fetch!(opts, :discord_client),
      presence_status: Keyword.fetch!(opts, :presence_status),
      jitter: Keyword.get_lazy(opts, :jitter, fn -> :rand.uniform() end)
    }

    Process.put(:"$callers", callers)
    Process.flag(:trap_exit, true)

    {:ok, state, {:continue, :connect}}
  end

  # Connect to Gateway
  # https://discord.com/developers/docs/events/gateway#connecting
  @impl GenServer
  def handle_continue(
        :connect,
        %__MODULE__{discord_client: discord_client} = state
      ) do
    {:ok, uri} = Discord.get_gateway(discord_client)
    {:ok, client} = WebsocketClient.connect(uri.host, uri.port, "/?v=10&encoding=json")
    {:noreply, %{state | websocket_client: client}}
  end

  # Receive Hello event and schedule first Heartbeat
  # https://discord.com/developers/docs/events/gateway#hello-event
  def handle_continue(
        {:event,
         [
           %{"op" => 10, "d" => %{"heartbeat_interval" => interval}, "s" => sequence_number}
           | events
         ]},
        state
      ) do
    (interval * state.jitter) |> round() |> schedule_heartbeat()
    state = identify(%{state | heartbeat_interval: interval, sequence_number: sequence_number})

    {:noreply, state, {:continue, {:event, events}}}
  end

  # Note Heartbeat ACK
  def handle_continue({:event, [%{"op" => 11} | events]}, state) do
    {:noreply, %{state | waiting_for_ack?: false}, {:continue, {:event, events}}}
  end

  # Respond to Heartbeat request
  # https://discord.com/developers/docs/events/gateway#heartbeat-requests
  def handle_continue(
        {:event, [%{"op" => 1} | events]},
        %__MODULE__{websocket_client: client, sequence_number: sequence_number} = state
      ) do
    {:ok, client} = WebsocketClient.send_event(client, %{op: 1, d: sequence_number})
    {:noreply, %{state | websocket_client: client}, {:continue, {:event, events}}}
  end

  def handle_continue({:event, [%{"op" => 0, "s" => s} | events]}, state) do
    {:noreply, %{state | sequence_number: s}, {:continue, {:event, events}}}
  end

  def handle_continue({:event, _events}, state) do
    {:noreply, state}
  end

  # Close connection if server failed to ACK Heartbeat
  # https://discord.com/developers/docs/events/gateway#heartbeat-interval-example-heartbeat-ack
  @impl GenServer
  def handle_info(
        :heartbeat,
        %__MODULE__{waiting_for_ack?: true, websocket_client: client} = state
      ) do
    {:ok, client} = WebsocketClient.begin_disconnect(client, 1008, "server missed ack")
    {:noreply, %{state | websocket_client: client, waiting_for_ack?: false}}
  end

  # Issue a normal scheduled Heartbeat
  def handle_info(
        :heartbeat,
        %__MODULE__{
          websocket_client: client,
          heartbeat_interval: interval,
          sequence_number: sequence_number
        } = state
      ) do
    {:ok, client} = WebsocketClient.send_event(client, %{op: 1, d: sequence_number})
    schedule_heartbeat(interval)
    {:noreply, %{state | websocket_client: client, waiting_for_ack?: true}}
  end

  def handle_info(message, %__MODULE__{websocket_client: client} = state) do
    case WebsocketClient.handle_message(client, message) do
      {:ok, :closed_by_server, reason} ->
        {:stop, {:shutdown, {:closed_by_server, reason}}, state}

      {:ok, :closed} ->
        {:stop, {:shutdown, :closed_by_client}, state}

      {:ok, client, messages} ->
        {:noreply, %{state | websocket_client: client}, {:continue, {:event, messages}}}

      {:error, _conn, error} when is_struct(error, Mint.WebSocket.UpgradeFailureError) ->
        {:stop, {:shutdown, error}, state}

      {:error, _conn, %{reason: :closed} = error, []}
      when is_struct(error, Mint.TransportError) ->
        {:stop, {:shutdown, error}, state}

      other ->
        {:stop, other, state}
    end
  end

  @impl GenServer
  def terminate({:shutdown, {:closed_by_server, _}}, _state), do: :ok
  def terminate({:shutdown, :closed_by_client}, _state), do: :ok
  def terminate({:shutdown, %Mint.TransportError{}}, _state), do: :ok

  def terminate(_other, %__MODULE__{websocket_client: %{state: :open, websocket: %{}} = client}) do
    WebsocketClient.begin_disconnect(client, 1000, "graceful disconnect")
  end

  def terminate(_other, _state), do: :ok

  defp schedule_heartbeat(schedule_in) do
    Process.send_after(self(), :heartbeat, schedule_in)
  end

  # Sending Identify event to update presence
  # https://discord.com/developers/docs/events/gateway#identifying
  defp identify(%__MODULE__{} = state) do
    identify_event = %{
      op: 2,
      d: %{
        token: state.bot_token,
        intents: 0,
        presence: %{
          activities: [%{type: 4, state: state.presence_status, name: "Name"}],
          since: nil,
          status: "online",
          afk: false
        },
        properties: %{
          os: "BEAM",
          browser: "DiscoLog",
          device: "DiscoLog"
        }
      }
    }

    {:ok, client} = WebsocketClient.send_event(state.websocket_client, identify_event)
    %{state | websocket_client: client}
  end
end
