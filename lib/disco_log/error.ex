defmodule DiscoLog.Error do
  @moduledoc false
  defstruct [
    :kind,
    :reason,
    :stacktrace,
    :display_title,
    :display_kind,
    :display_short_error,
    :display_full_error,
    :display_source,
    :fingerprint_basis,
    :fingerprint,
    :source_url
  ]

  @type t() :: %__MODULE__{}

  @title_limit 80
  @short_error_limit 60

  def new({{:nocatch, reason}, stacktrace}), do: new(:throw, reason, stacktrace)
  def new({reason, stacktrace}) when is_exception(reason), do: new(:error, reason, stacktrace)
  def new({reason, stacktrace}), do: new(:exit, reason, stacktrace)

  def new(kind, reason, stacktrace) do
    %__MODULE__{
      kind: kind,
      reason: Exception.normalize(kind, reason, stacktrace),
      stacktrace: stacktrace
    }
    |> put_display_kind()
    |> put_display_short_error()
    |> put_display_full_error()
    |> put_display_title()
  end

  def enrich(%__MODULE__{} = error, config) do
    maybe_last_app_entry =
      case error.stacktrace do
        [first | _] ->
          Enum.find(error.stacktrace, first, fn {module, _, _, _} ->
            module in config.in_app_modules
          end)

        _ ->
          nil
      end

    display_source =
      if maybe_last_app_entry, do: Exception.format_stacktrace_entry(maybe_last_app_entry)

    source_url = compose_source_url(maybe_last_app_entry, config)

    fingeprintable_error =
      case error do
        %{reason: %module{} = exception} when is_exception(exception) ->
          module

        %{kind: kind} ->
          kind
      end

    fingerprintable_stacktrace_entry =
      with {module, function, args, opts} when is_list(args) <- maybe_last_app_entry do
        {module, function, length(args), opts}
      end

    basis = {fingeprintable_error, fingerprintable_stacktrace_entry}

    %{
      error
      | fingerprint_basis: basis,
        fingerprint: fingerprint(basis),
        source_url: source_url,
        display_source: display_source
    }
  end

  def fingerprint(basis) do
    hash = :erlang.phash2(basis, 2 ** 32)
    Base.url_encode64(<<hash::32>>, padding: false)
  end

  defp compose_source_url({module, _, _, opts}, %{enable_go_to_repo: true} = config) do
    with true <- in_app_module?(module, config),
         file when not is_nil(file) <- Keyword.get(opts, :file) do
      "#{config[:repo_url]}/#{config[:git_sha]}/#{file}#L#{opts[:line]}"
    else
      _ -> nil
    end
  end

  defp compose_source_url(_, _), do: nil

  defp in_app_module?(module, config) do
    with false <- module in config.in_app_modules,
         true <- function_exported?(module, :__info__, 2) do
      [top_level | _] = Module.split(module)
      top_level in config.go_to_repo_top_modules
    end
  end

  defp put_display_kind(%__MODULE__{} = error) do
    if is_exception(error.reason) do
      %{error | display_kind: inspect(error.reason.__struct__)}
    else
      error
    end
  end

  defp put_display_short_error(%__MODULE__{} = error) do
    formatted =
      if is_exception(error.reason) do
        Exception.message(error.reason)
      else
        Exception.format_banner(error.kind, error.reason, error.stacktrace)
      end

    %{error | display_short_error: to_oneliner(formatted, @short_error_limit)}
  end

  defp put_display_full_error(%__MODULE__{} = error) do
    formatted = Exception.format(error.kind, error.reason, error.stacktrace)
    %{error | display_full_error: formatted}
  end

  defp put_display_title(%__MODULE__{} = error) do
    if is_exception(error.reason) do
      formatted = Exception.format_banner(error.kind, error.reason, error.stacktrace)
      %{error | display_title: to_oneliner(formatted, @title_limit)}
    else
      %{error | display_title: error.display_short_error}
    end
  end

  defp to_oneliner(text, limit) do
    line =
      text
      |> String.split("\n", parts: 2)
      |> hd()

    truncated =
      if String.length(line) <= limit do
        line
      else
        line
        |> String.split(": ", parts: 2)
        |> hd()
        |> String.slice(0, limit)
      end

    if String.length(truncated) < String.length(text) do
      truncated <> " \u2026"
    else
      truncated
    end
  end
end
