defmodule DiscoLog.Discord do
  @moduledoc false

  alias DiscoLog.Discord.API
  alias DiscoLog.Discord.Prepare

  def list_occurrence_threads(discord_client, guild_id, occurrences_channel_id) do
    case API.list_active_threads(discord_client, guild_id) do
      {:ok, %{status: 200, body: %{"threads" => threads}}} ->
        active_threads =
          threads
          |> Enum.filter(&(&1["parent_id"] == occurrences_channel_id))
          |> Enum.map(&{Prepare.fingerprint_from_thread_name(&1["name"]), &1["id"]})
          |> Map.new()

        {:ok, active_threads}

      {:ok, response} ->
        {:error, response}

      other ->
        other
    end
  end

  def list_occurrence_tags(discord_client, occurrences_channel_id) do
    case API.get_channel(discord_client, occurrences_channel_id) do
      {:ok, %{status: 200, body: %{"available_tags" => available_tags}}} ->
        tags = for %{"id" => id, "name" => name} <- available_tags, into: %{}, do: {name, id}
        {:ok, tags}

      {:ok, response} ->
        {:error, response}

      error ->
        error
    end
  end

  def get_gateway(discord_client) do
    case API.get_gateway(discord_client) do
      {:ok, %{status: 200, body: %{"url" => raw_uri}}} -> URI.new(raw_uri)
      {:ok, response} -> {:error, response}
      error -> error
    end
  end

  def delete_threads(discord_client, guild_id, channel_id) do
    {:ok, %{status: 200, body: %{"threads" => threads}}} =
      API.list_active_threads(discord_client, guild_id)

    threads
    |> Enum.filter(&(&1["parent_id"] == channel_id))
    |> Enum.map(fn %{"id" => thread_id} ->
      {:ok, %{status: 200}} = API.delete_thread(discord_client, thread_id)
    end)
  end

  def delete_channel_messages(discord_client, channel_id) do
    {:ok, %{status: 200, body: messages}} = API.get_channel_messages(discord_client, channel_id)

    for %{"id" => message_id} <- messages do
      API.delete_message(discord_client, channel_id, message_id)
    end
  end
end
