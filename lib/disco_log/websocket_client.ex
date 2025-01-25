defmodule DiscoLog.WebsocketClient do
  @moduledoc false
  @compile {:no_warn_undefined, __MODULE__.Impl}
  @adapter Application.compile_env(:disco_log, :websocket_adapter, __MODULE__.Impl)

  defstruct [:conn, :websocket, :ref, :state]

  @type t :: %__MODULE__{
          conn: Mint.HTTP.t(),
          ref: Mint.Types.request_ref(),
          websocket: Mint.WebSocket.t(),
          state: :open | :closing
        }

  @callback connect(host :: Mint.Types.address(), port :: :inet.port_number(), path :: String.t()) ::
              {:ok, t()} | {:error, Mint.WebSocket.error()}
  defdelegate connect(host, port, path), to: @adapter

  @callback boil_message_to_frame(client :: t(), message :: any()) ::
              {:ok, t(), Mint.WebSocket.frame() | nil}
              | {:error, Mint.HTTP.t(), Mint.Types.error(), [Mint.Types.response()]}
              | {:error, Mint.HTTP.t(), Mint.WebSocket.error()}
              | {:error, Mint.WebSocket.t(), any()}
              | :unknown
  defdelegate boil_message_to_frame(client, message), to: @adapter

  @callback send_frame(client :: t(), frame :: Mint.WebSocket.frame()) ::
              {:ok, t()}
              | {:error, Mint.WebSocket.t(), any()}
              | {:error, Mint.HTTP.t(), Mint.Types.error()}
  defdelegate send_frame(client, event), to: @adapter

  @callback close(client :: t()) :: {:ok, Mint.HTTP.t()}
  defdelegate close(client), to: @adapter

  def send_event(client, event), do: send_frame(client, {:text, Jason.encode!(event)})

  def begin_disconnect(client, code, reason) do
    with {:ok, client} <- send_frame(client, {:close, code, reason}) do
      {:ok, %{client | state: :closing}}
    end
  end

  def handle_message(client, message) do
    with {:ok, client, frame} <- boil_message_to_frame(client, message) do
      handle_frame(client, frame)
    end
  end

  defp handle_frame(client, text: text), do: {:ok, client, Jason.decode!(text)}

  defp handle_frame(%__MODULE__{state: :closing} = client, [{:close, _code, _reason}]) do
    with {:ok, _conn} <- close(client) do
      {:ok, :closed}
    end
  end

  defp handle_frame(client, [{:close, _code, reason}]) do
    with {:ok, _client} <- ack_server_closure(client) do
      {:ok, :closed_by_server, reason}
    end
  end

  defp handle_frame(client, nil), do: {:ok, client, nil}
  defp handle_frame(client, []), do: {:ok, client, nil}

  defp ack_server_closure(client) do
    with {:ok, client} <- send_frame(client, :close),
         {:ok, conn} <- close(client) do
      {:ok, %{client | conn: conn, websocket: nil}}
    end
  end
end
