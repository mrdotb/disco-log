defmodule DiscoLog.Discord.Prepare do
  @moduledoc false
  alias DiscoLog.Encoder

  def prepare_message(message, metadata) when is_binary(message) do
    [
      payload_json: Encoder.encode!(%{content: message})
    ]
    |> maybe_put_metadata(metadata)
  end

  def prepare_message(message, metadata) when is_map(message) do
    [
      message: {Encoder.encode!(message, pretty: true), filename: "message.json"}
    ]
    |> maybe_put_metadata(metadata)
  end

  def prepare_occurrence(error, tags) do
    [
      payload_json:
        Encoder.encode!(%{
          message: prepare_error_message(error),
          name: thread_name(error),
          applied_tags: tags
        })
    ]
    |> put_stacktrace(error.stacktrace)
    |> maybe_put_context(error.context)
  end

  def prepare_occurrence_message(error) do
    [
      payload_json: Encoder.encode!(prepare_error_message(error))
    ]
    |> put_stacktrace(error.stacktrace)
    |> maybe_put_context(error.context)
  end

  def fingerprint_from_thread_name(<<fingerprint::binary-size(16)>> <> " " <> _rest),
    do: fingerprint

  # Thread name are limited by 100 characters we use the 16 first characters for the fingerprint
  defp thread_name(error), do: "#{error.fingerprint} #{error.kind}"

  defp maybe_put_metadata(fields, metadata) when map_size(metadata) == 0, do: fields

  defp maybe_put_metadata(fields, metadata) do
    Keyword.put(
      fields,
      :metadata,
      {serialize_metadata(metadata), filename: "metadata.ex"}
    )
  end

  defp serialize_metadata(metadata) do
    metadata
    |> inspect(pretty: true, limit: :infinity, printable_limit: :infinity)
    # 8MB is the max file attachment limit
    |> String.byte_slice(0, 8_000_000)
  end

  defp prepare_error_message(error) do
    %{
      content: """
        **At:** <t:#{System.os_time(:second)}:T>
        **Kind:** `#{error.kind}`
        **Reason:** `#{error.reason}`
        **Source Line:** #{source_line(error)}
        **Source Function:** `#{error.source_function}`
        **Fingerprint:** `#{error.fingerprint}`
      """
    }
  end

  # source line can be a link to the source code if source_url is set
  defp source_line(error) do
    if error.source_url do
      # we wrap the url with `<>` to prevent an embed preview to be created
      "[`#{error.source_line}`](<#{error.source_url}>)"
    else
      "`#{error.source_line}`"
    end
  end

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
end
