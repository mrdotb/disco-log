if Code.ensure_loaded?(Mint.WebSocket) do
  defmodule DiscoLog.WebsocketClient.Impl do
    @moduledoc false
    alias DiscoLog.WebsocketClient

    @behaviour WebsocketClient

    @impl WebsocketClient
    def connect(host, port, path) do
      with {:ok, conn} <- Mint.HTTP.connect(:https, host, port, protocols: [:http1]),
           {:ok, conn, ref} <- Mint.WebSocket.upgrade(:wss, conn, path, []) do
        {:ok, %WebsocketClient{conn: conn, ref: ref, state: :open}}
      end
    end

    @impl WebsocketClient
    def boil_message_to_frame(%WebsocketClient{conn: conn} = client, message) do
      with {:ok, conn, tcp_message} <- Mint.WebSocket.stream(conn, message) do
        handle_tcp_message(%{client | conn: conn}, tcp_message)
      end
    end

    @impl WebsocketClient
    def send_frame(%WebsocketClient{conn: conn, websocket: websocket, ref: ref} = client, frame) do
      with {:ok, websocket, data} <-
             Mint.WebSocket.encode(websocket, frame),
           {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data) do
        {:ok, %{client | conn: conn, websocket: websocket}}
      end
    end

    @impl WebsocketClient
    def close(%WebsocketClient{conn: conn}), do: Mint.HTTP.close(conn)

    defp handle_tcp_message(%WebsocketClient{conn: conn, ref: ref} = client, [
           {:status, ref, 101},
           {:headers, ref, headers} | frames
         ]) do
      with {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, 101, headers) do
        client = %{client | conn: conn, websocket: websocket}

        if data_frame = Enum.find(frames, &match?({:data, ^ref, _}, &1)) do
          handle_tcp_message(client, [data_frame])
        else
          {:ok, client, nil}
        end
      end
    end

    defp handle_tcp_message(%WebsocketClient{ref: ref, websocket: websocket} = client, [
           {:data, ref, data}
         ]) do
      with {:ok, websocket, frame} <- Mint.WebSocket.decode(websocket, data) do
        {:ok, %{client | websocket: websocket}, frame}
      end
    end
  end
end
