defmodule DiscoLog.Discord.Presence do
  @moduledoc """
  Use the Discord Gateway API to send presence updates.

  https://discord.com/developers/docs/topics/gateway#gateway
  """
  use GenServer

  require Logger

  @discord_gateway_url "wss://gateway.discord.gg/?v=10&encoding=json"

  defstruct ~w(conn websocket request_ref called status resp_headers closing?)a

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    uri = URI.parse(@discord_gateway_url)

    with {:ok, conn} <- Mint.HTTP.connect(:https, uri.host, uri.port, protocols: [:http1]),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(:wss, conn, "#{uri.path}?#{uri.query}", []) do
      Logger.debug("WebSocket connection initiated")
      {:noreply, %{state | conn: conn, request_ref: ref}}
    else
      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:stop, reason, state}
    end
  end
end
