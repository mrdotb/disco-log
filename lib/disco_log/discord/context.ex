defmodule DiscoLog.Discord.Context do
  @moduledoc """
  Context around Discord.
  """

  alias DiscoLog.Discord
  alias DiscoLog.Encoder

  def fetch_or_create_channel(channels, channel_config, parent_id) do
    case Enum.find(channels, &find_channel(&1, channel_config)) do
      channel when is_map(channel) ->
        {:ok, channel}

      nil ->
        channel_config
        |> maybe_add_parent_id(parent_id)
        |> Discord.Client.create_channel()
    end
  end

  def maybe_delete_channel(channels, channel_config) do
    case Enum.find(channels, &find_channel(&1, channel_config)) do
      channel when is_map(channel) ->
        Discord.Client.delete_channel(channel["id"])

      nil ->
        :ok
    end
  end

  defp find_channel(channel, config) do
    channel["type"] == config[:type] and channel["name"] == config[:name]
  end

  defp maybe_add_parent_id(params, nil), do: params

  defp maybe_add_parent_id(params, parent_id) do
    Map.put(params, :parent_id, parent_id)
  end

  def create_occurrence_thread(error) do
    error
    |> prepare_occurrence_thread_fields()
    |> Discord.Client.create_form_forum_thread()
  end

  def create_occurrence_message(thread_id, error) do
    error
    |> prepare_occurrence_message_fields()
    |> Discord.Client.create_form_message(channel_id: thread_id)
  end

  def list_occurrence_threads do
    {:ok, response} = Discord.Client.list_active_threads()

    response["threads"]
    |> Enum.filter(&(&1["parent_id"] == Discord.Config.occurrences_channel_id()))
    |> Enum.map(&{extract_fingerprint(&1["name"]), &1["id"]})
  end

  defp prepare_occurrence_thread_fields(error) do
    [
      payload_json:
        Encoder.encode!(
          %{
            name: thread_name(error),
            message: prepare_error_message(error)
          }
          |> maybe_put_tag(error.context)
        )
    ]
    |> put_stacktrace(error.stacktrace)
    |> maybe_put_context(error.context)
  end

  defp prepare_occurrence_message_fields(error) do
    [
      payload_json: Encoder.encode!(prepare_error_message(error))
    ]
    |> put_stacktrace(error.stacktrace)
    |> maybe_put_context(error.context)
  end

  defp prepare_error_message(error) do
    %{
      content: """
        **At:** <t:#{System.os_time(:second)}:T>
        **Kind:** `#{error.kind}`
        **Reason:** `#{error.reason}`
        **Source Line:** `#{error.source_line}`
        **Source Function:** `#{error.source_function}`
        **Fingerprint:** `#{error.fingerprint}`
      """
      # Maybe there is something nice to do with embeds fields
      # https://discordjs.guide/popular-topics/embeds.html#embed-preview
      # embeds: [
      #   %{
      #     fields: [
      #       %{name: "at", value: "<t:#{System.os_time(:second)}:T>"},
      #       %{name: "kind", value: backtick_wrap(error.kind)},
      #       %{name: "reason", value: backtick_wrap(error.reason)},
      #       %{name: "source_line", value: backtick_wrap(error.source_line)},
      #       %{name: "source_function", value: backtick_wrap(error.source_function)},
      #       %{name: "fingerprint", value: backtick_wrap(error.fingerprint)}
      #     ]
      #   }
      # ]
    }
  end

  # defp backtick_wrap(string), do: "`#{string}`"

  defp maybe_put_tag(message, context) do
    context
    |> Map.keys()
    |> Enum.filter(&(&1 in Discord.Config.tags()))
    |> Enum.map(&Discord.Config.occurrences_channel_tag_id(&1))
    |> case do
      [] -> message
      tags -> Map.put(message, :applied_tags, tags)
    end
  end

  # Thread name are limited by 100 characters we use the 16 first characters for the fingerprint
  defp thread_name(error), do: "#{error.fingerprint} #{error.kind}"

  defp extract_fingerprint(<<fingerprint::binary-size(16)>> <> " " <> _rest),
    do: fingerprint

  defp put_stacktrace(fields, stacktrace) do
    Keyword.put(fields, :stacktrace, {to_string(stacktrace), filename: "stacktrace.ex"})
  end

  defp maybe_put_context(fields, context) when map_size(context) == 0, do: fields

  defp maybe_put_context(fields, context) do
    Keyword.put(
      fields,
      :context,
      {Encoder.encode!(context, pretty: true), filename: "context.json"}
    )
  end

  def create_message(channel_id, message, metadata) when is_binary(message) do
    [
      payload_json:
        Encoder.encode!(%{
          content: message
        })
    ]
    |> maybe_put_metadata(metadata)
    |> Discord.Client.create_form_message(channel_id: channel_id)
  end

  def create_message(channel_id, message, metadata) when is_map(message) do
    [
      message: {Encoder.encode!(message, pretty: true), filename: "message.json"}
    ]
    |> maybe_put_metadata(metadata)
    |> Discord.Client.create_form_message(channel_id: channel_id)
  end

  defp maybe_put_metadata(fields, metadata) when map_size(metadata) == 0, do: fields

  defp maybe_put_metadata(fields, metadata) do
    Keyword.put(
      fields,
      :metadata,
      {Encoder.encode!(metadata, pretty: true), filename: "metadata.json"}
    )
  end

  def delete_threads(channel_id) do
    {:ok, response} = Discord.Client.list_active_threads()

    response["threads"]
    |> Enum.filter(&(&1["parent_id"] == channel_id))
    |> Enum.map(&Discord.Client.delete_thread(&1["id"]))
  end

  def delete_channel_messages(channel_id) do
    {:ok, response} = Discord.Client.list_messages(channel_id)

    response
    |> Enum.map(& &1["id"])
    |> Enum.map(&Discord.Client.delete_message(channel_id, &1))
  end
end
