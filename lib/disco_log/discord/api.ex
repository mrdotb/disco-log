defmodule DiscoLog.Discord.API do
  @moduledoc """
  A module for working with Discord REST API.
  https://discord.com/developers/docs/reference

  This module is also a behavior. The default implementation uses the `Req` HTTP client. 
  If you want to use a different client, you'll need to implement the behavior and 
  put it under the `discord_client_module` configuration option.
  """

  require Logger

  defstruct [:client, :module, :log?]

  @typedoc """
  The client can be any term. It is passed as a first argument to `c:request/4`. For example, the 
  default `DiscoLog.Discord.API.Client` client uses `Req.Request.t()` as a client.
  """
  @type client() :: any()
  @type response() :: {:ok, %{status: non_neg_integer(), body: any()}} | {:error, Exception.t()}
  @type t() :: %__MODULE__{client: client(), module: atom()}

  @callback client(token :: String.t()) :: t()
  @callback request(client :: client(), method :: atom(), url :: String.t(), opts :: keyword()) ::
              response()

  @spec list_active_threads(client(), String.t()) :: response()
  def list_active_threads(%__MODULE__{} = client, guild_id) do
    with_log(client, :get, "/guilds/:guild_id/threads/active", path_params: [guild_id: guild_id])
  end

  @spec list_channels(client(), String.t()) :: response()
  def list_channels(%__MODULE__{} = client, guild_id) do
    with_log(client, :get, "/guilds/:guild_id/channels", path_params: [guild_id: guild_id])
  end

  @spec get_channel(client(), String.t()) :: response()
  def get_channel(%__MODULE__{} = client, channel_id) do
    with_log(client, :get, "/channels/:channel_id", path_params: [channel_id: channel_id])
  end

  @spec get_channel_messages(client(), String.t()) :: response()
  def get_channel_messages(%__MODULE__{} = client, channel_id) do
    with_log(client, :get, "/channels/:channel_id/messages",
      path_params: [channel_id: channel_id]
    )
  end

  @spec get_gateway(client()) :: response()
  def get_gateway(%__MODULE__{} = client) do
    with_log(client, :get, "/gateway/bot", [])
  end

  @spec create_channel(client(), String.t(), map()) :: response()
  def create_channel(%__MODULE__{} = client, guild_id, body) do
    with_log(client, :post, "/guilds/:guild_id/channels",
      path_params: [guild_id: guild_id],
      json: body
    )
  end

  @spec post_message(client(), String.t(), Keyword.t()) :: response()
  def post_message(%__MODULE__{} = client, channel_id, fields) do
    with_log(client, :post, "/channels/:channel_id/messages",
      path_params: [channel_id: channel_id],
      form_multipart: fields
    )
  end

  @spec post_thread(client(), String.t(), Keyword.t()) :: response()
  def post_thread(%__MODULE__{} = client, channel_id, fields) do
    with_log(client, :post, "/channels/:channel_id/threads",
      path_params: [channel_id: channel_id],
      form_multipart: fields
    )
  end

  @spec delete_thread(client(), String.t()) :: response()
  def delete_thread(%__MODULE__{} = client, thread_id) do
    with_log(client, :delete, "/channels/:thread_id", path_params: [thread_id: thread_id])
  end

  @spec delete_message(client(), String.t(), String.t()) :: response()
  def delete_message(%__MODULE__{} = client, channel_id, message_id) do
    with_log(client, :delete, "/channels/:channel_id/messages/:message_id",
      path_params: [channel_id: channel_id, message_id: message_id]
    )
  end

  @spec delete_channel(client(), String.t()) :: response()
  def delete_channel(%__MODULE__{} = client, channel_id) do
    with_log(client, :delete, "/channels/:channel_id", path_params: [channel_id: channel_id])
  end

  defp with_log(client, method, url, opts) do
    resp = client.module.request(client.client, method, url, opts)

    if client.log? do
      request = "#{method |> to_string() |> String.upcase()} #{to_string(url)}\n"

      response =
        case resp do
          {:ok, resp} ->
            "Status: #{inspect(resp.status)}\nBody: #{inspect(resp.body, pretty: true)}"

          {:error, error} ->
            "Error: #{inspect(error, pretty: true)}"
        end

      Logger.debug("Request: #{request}\n#{inspect(opts, pretty: true)}\n#{response}")
    end

    resp
  end
end
