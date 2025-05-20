defmodule DiscoLog.Discord.Prepare do
  @moduledoc false

  @text_display_type 10
  @components_flag 32_768
  @max_title_length 100
  @displayed_message_limit 4000
  @context_overhead String.length("```elixir\n\n```")
  @file_attachment_limit 8_000_000

  def prepare_message(message, context) do
    context_budget = context_budget(message)

    base_message = %{
      flags: @components_flag,
      components: [
        %{
          type: @text_display_type,
          content: message
        }
      ]
    }

    append_context(base_message, prepare_context(context, context_budget))
  end

  def prepare_occurrence(error, context, applied_tags) do
    content_component = prepare_main_content(error)
    context_budget = context_budget(content_component.content)

    %{
      name: String.slice(error.fingerprint <> " " <> error.display_title, 0, @max_title_length),
      applied_tags: applied_tags,
      message: %{
        flags: @components_flag,
        components: []
      }
    }
    |> append_component(content_component)
    |> append_context(prepare_context(context, context_budget))
  end

  def prepare_occurrence_message(error, context) do
    content_component = prepare_main_content(error)
    context_budget = context_budget(content_component.content)

    %{
      flags: @components_flag,
      components: []
    }
    |> append_component(content_component)
    |> append_context(prepare_context(context, context_budget))
  end

  def fingerprint_from_thread_name(<<fingerprint::binary-size(6)>> <> " " <> _rest),
    do: fingerprint

  def fingerprint_from_thread_name(_), do: nil

  defp prepare_main_content(error) do
    source_line =
      case error do
        %{display_source: nil} -> nil
        %{source_url: nil} -> "**Source:** `#{error.display_source}`"
        _ -> "**Source:** [#{error.display_source}](#{error.source_url})"
      end

    kind_line =
      if error.display_kind, do: "**Kind:** `#{error.display_kind}`"

    content =
      [
        kind_line,
        "**Reason:** `#{error.display_short_error}`",
        source_line,
        "```\n#{error.display_full_error}\n```"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    %{
      type: @text_display_type,
      content: content
    }
  end

  defp prepare_context(_, context_budget) when context_budget <= 0, do: nil
  defp prepare_context(nil, _context_budget), do: nil

  defp prepare_context(context, _context_budget) when is_map(context) and map_size(context) == 0,
    do: nil

  defp prepare_context(context, context_budget) do
    context
    |> inspect(pretty: true, limit: :infinity, printable_limit: :infinity)
    |> String.split_at(context_budget)
    |> case do
      {full, ""} ->
        %{
          type: @text_display_type,
          content: "```elixir\n#{full}\n```"
        }

      {left, right} ->
        {String.byte_slice(left <> right, 0, @file_attachment_limit), [filename: "context.txt"]}
    end
  end

  defp append_component(%{components: components} = message, %{} = component) do
    put_in(message, [:components], components ++ [component])
  end

  defp append_component(%{message: %{components: components}} = message, %{} = component) do
    put_in(message, [:message, :components], components ++ [component])
  end

  defp append_component(message, _), do: message

  defp append_context(message, {_, _} = context_attachment) do
    [
      payload_json:
        append_component(message, %{type: 13, file: %{url: "attachment://context.txt"}}),
      context: context_attachment
    ]
  end

  defp append_context(message, context_component) do
    [payload_json: append_component(message, context_component)]
  end

  defp context_budget(main_content),
    do: @displayed_message_limit - String.length(main_content) - @context_overhead
end
