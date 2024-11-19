defmodule DiscoLog.Discord.Client do
  @moduledoc """
  This module contains the Discord API client.
  """

  require Logger

  @base_url "https://discord.com/api/v10"
  @version DiscoLog.MixProject.project()[:version]

  def list_channels(config) do
    case Req.get!(client(config), url: "/guilds/#{config.guild_id}/channels") do
      %Req.Response{status: 200, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to list channels"}
    end
  end

  def create_channel(config, params) do
    case Req.post!(
           client(config),
           url: "/guilds/#{config.guild_id}/channels",
           json: params
         ) do
      %Req.Response{status: 201, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to create channel"}
    end
  end

  def delete_channel(config, channel_id) do
    case Req.delete!(client(config), url: "/channels/#{channel_id}") do
      %Req.Response{status: 204} ->
        :ok

      _ ->
        {:error, "Failed to delete channel"}
    end
  end

  def list_active_threads(config) do
    case Req.get!(client(config), url: "/guilds/#{config.guild_id}/threads/active") do
      %Req.Response{status: 200, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to list threads"}
    end
  end

  def create_form_forum_thread(config, fields) do
    case Req.post!(client(config),
           url: "/channels/#{config.occurrences_channel_id}/threads",
           form_multipart: fields
         ) do
      %Req.Response{status: 201, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to create forum thread"}
    end
  end

  def delete_thread(config, thread_id) do
    case Req.delete!(client(config), url: "/channels/#{thread_id}") do
      %Req.Response{status: 204} ->
        :ok

      _ ->
        {:error, "Failed to delete thread"}
    end
  end

  def create_form_message(config, channel_id, fields) do
    case Req.post!(client(config),
           url: "/channels/#{channel_id}/messages",
           form_multipart: fields
         ) do
      %Req.Response{status: 200, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to create form message"}
    end
  end

  def create_json_message(config, channel_id, params) do
    case Req.post!(client(config), url: "/channels/#{channel_id}/messages", json: params) do
      %Req.Response{status: 200, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to create json message"}
    end
  end

  def list_messages(config, channel_id, params \\ []) do
    case Req.get!(client(config), url: "/channels/#{channel_id}/messages", params: params) do
      %Req.Response{status: 200, body: body} ->
        {:ok, body}

      _ ->
        {:error, "Failed to list messages"}
    end
  end

  def delete_message(config, channel_id, message_id) do
    case Req.delete!(client(config),
           url: "/channels/#{channel_id}/messages/#{message_id}",
           max_retries: 10
         ) do
      %Req.Response{status: 204} ->
        :ok

      _ ->
        {:error, "Failed to delete message"}
    end
  end

  def client(config) do
    Req.new(
      base_url: @base_url,
      headers: [
        {"User-Agent", "DiscoLog (https://github.com/mrdotb/disco-log, #{@version})"},
        {"Authorization", "Bot #{config.token}"}
      ]
    )
    |> maybe_add_debug_log(config.enable_discord_log)
  end

  defp maybe_add_debug_log(request, false), do: request

  defp maybe_add_debug_log(request, true) do
    Req.Request.append_response_steps(request, log_response: &log_response/1)
  end

  defp log_response({req, res} = result) do
    Logger.debug("""
      Request: #{inspect(to_string(req.url), pretty: true)}
      Request: #{inspect(to_string(req.body), pretty: true)}
      Status: #{inspect(res.status, pretty: true)}
      Body: #{inspect(res.body, pretty: true)}
    """)

    result
  end
end
