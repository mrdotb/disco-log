defmodule DiscoLog.Discord.Prepare do
  @moduledoc false

  @text_display_type 10
  @components_flag 32_768
  @max_title_length 100
  @displayed_message_limit 4000
  @context_overhead String.length("```elixir\n\n```")
  @file_attachment_limit 8_000_000
  @full_error_overhead String.length("```\n\n```")

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

    append_component(base_message, prepare_context(context, context_budget))
  end

  def prepare_occurrence(error, context, applied_tags) do
    %{
      name: String.slice(error.fingerprint <> " " <> error.display_title, 0, @max_title_length),
      applied_tags: applied_tags,
      message: %{
        flags: @components_flag,
        components: []
      }
    }
    |> append_component(prepare_main_content(error))
    |> then(fn payload ->
      budget = full_error_budget(payload)
      append_component(payload, prepare_full_error_content(error, budget))
    end)
    |> then(fn payload ->
      budget = context_budget(payload)
      append_component(payload, prepare_context(context, budget))
    end)
  end

  def prepare_occurrence_message(error, context) do
    %{
      flags: @components_flag,
      components: []
    }
    |> append_component(prepare_main_content(error))
    |> then(fn payload ->
      budget = full_error_budget(payload)
      append_component(payload, prepare_full_error_content(error, budget))
    end)
    |> then(fn payload ->
      budget = context_budget(payload)
      append_component(payload, prepare_context(context, budget))
    end)
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
        source_line
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    %{
      type: @text_display_type,
      content: content
    }
  end

  defp prepare_full_error_content(%{display_full_error: nil}, _full_error_budget), do: nil

  defp prepare_full_error_content(error, full_error_budget) when full_error_budget <= 0 do
    {:error,
     {String.byte_slice(error.display_full_error, 0, @file_attachment_limit),
      [filename: "error.txt"]}}
  end

  defp prepare_full_error_content(error, full_error_budget) do
    if String.length(error.display_full_error) <= full_error_budget do
      %{type: @text_display_type, content: "```\n#{error.display_full_error}\n```"}
    else
      prepare_full_error_content(error, 0)
    end
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
        {:context,
         {String.byte_slice(left <> right, 0, @file_attachment_limit), [filename: "context.txt"]}}
    end
  end

  defp append_component(%{} = message, component) do
    append_component([payload_json: message], component)
  end

  defp append_component(
         [{:payload_json, %{message: %{components: components}}} | _] = payload,
         %{} = component
       ) do
    put_in(payload, [:payload_json, :message, :components], components ++ [component])
  end

  defp append_component(
         [{:payload_json, %{components: components}} | _] = payload,
         %{} = component
       ) do
    put_in(payload, [:payload_json, :components], components ++ [component])
  end

  defp append_component(
         [_ | _] = payload,
         {_filename, {_, [filename: full_filename]}} = attachment
       ) do
    append_component(payload ++ [attachment], %{
      type: 13,
      file: %{url: "attachment://#{full_filename}"}
    })
  end

  defp append_component(message, _), do: message

  defp context_budget(main_content),
    do: @displayed_message_limit - content_length(main_content) - @context_overhead

  defp full_error_budget(main_content),
    do: @displayed_message_limit - content_length(main_content) - @full_error_overhead

  defp content_length([{:payload_json, %{message: %{components: components}}} | _]) do
    Enum.sum_by(components, fn
      %{content: content} -> String.length(content)
      _ -> 0
    end)
  end

  defp content_length([{:payload_json, %{components: components}} | _]) do
    Enum.sum_by(components, fn
      %{content: content} -> String.length(content)
      _ -> 0
    end)
  end

  defp content_length(string), do: String.length(string)
end
