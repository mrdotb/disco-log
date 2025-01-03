defmodule DiscoLog.Error do
  @moduledoc """
  Struct for error or exception.
  """

  alias __MODULE__
  alias DiscoLog.Stacktrace

  @type t :: %Error{
          kind: atom() | String.t(),
          reason: String.t(),
          source_line: String.t(),
          source_function: String.t(),
          context: any(),
          stacktrace: Stacktrace.t(),
          fingerprint: String.t(),
          source_url: String.t() | nil
        }

  defstruct ~w(kind reason source_line source_function context stacktrace fingerprint source_url)a

  def new(exception, stacktrace, context, config) do
    {kind, reason} = normalize_exception(exception, stacktrace)
    stacktrace = Stacktrace.new(stacktrace)
    source = Stacktrace.source(stacktrace, config.otp_app)

    source_line =
      if is_map(source) and is_binary(source.file) and source.file != "",
        do: "#{source.file}:#{source.line}",
        else: "nofile"

    source_function =
      if is_map(source),
        do: "#{source.module}.#{source.function}/#{source.arity}",
        else: "nofunction"

    source_url =
      with true <- config.enable_go_to_repo,
           %{file: file} = app_source when is_binary(file) and file != "" <-
             Stacktrace.app_source(stacktrace, config.otp_app, config.go_to_repo_top_modules) do
        get_source_url(config, app_source)
      else
        _ -> nil
      end

    %Error{
      kind: kind,
      reason: reason,
      source_line: source_line,
      source_function: source_function,
      context: context,
      stacktrace: stacktrace,
      fingerprint: fingerprint(kind, source_line, source_function),
      source_url: source_url
    }
  end

  defp normalize_exception(%struct{} = ex, _stacktrace) when is_exception(ex) do
    {to_string(struct), Exception.message(ex)}
  end

  defp normalize_exception({kind, ex}, stacktrace) do
    case Exception.normalize(kind, ex, stacktrace) do
      %struct{} = ex ->
        {to_string(struct), Exception.message(ex)}

      {mod, fun, args} ->
        {to_string(kind),
         to_string(mod) <> "." <> to_string(fun) <> "/" <> to_string(Enum.count(args))}

      other ->
        {to_string(kind), to_string(other)}
    end
  end

  defp normalize_exception(:bad_exit, []) do
    {"exit", "bad_exit"}
  end

  defp normalize_exception(reason, _other) when is_atom(reason) do
    {reason, "unknow"}
  end

  # Fingerprint is used to group the similar errors together
  # Original implementation from https://github.com/elixir-error-tracker/error-tracker/blob/main/lib/error_tracker/schemas/error.ex#L40
  defp fingerprint(kind, source_line, source_function) do
    values = Enum.join([kind, source_line, source_function])
    hash = :crypto.hash(:sha256, values)
    Base.encode16(hash) |> binary_part(0, 16)
  end

  @doc """
  Used to compare errors for deduplication original implementation from Sentry Elixir
  https://github.com/getsentry/sentry-elixir/blob/69ac8d0e3f33ff36ab1092bbd346fdb99cf9d061/lib/sentry/event.ex#L613
  """
  def hash(%Error{} = error) do
    :erlang.phash2([
      error.kind,
      error.reason,
      error.stacktrace,
      error.context
    ])
  end

  defp get_source_url(config, source) do
    "#{config[:repo_url]}/#{config[:git_sha]}/#{source.file}#L#{source.line}"
  end
end
