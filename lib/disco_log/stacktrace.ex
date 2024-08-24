defmodule DiscoLog.Stacktrace do
  @moduledoc """
  A struct that contains the information about the execution stack for a given
  occurrence of an exception.
  """

  alias __MODULE__

  defmodule Line do
    @moduledoc false
    defstruct ~w(application module function arity file line)a
  end

  defstruct ~w(lines)a

  def new(stack) do
    lines_params =
      for {module, function, arity, opts} <- stack do
        application = Application.get_application(module)

        %Line{
          application: to_string(application),
          module: module |> to_string() |> String.replace_prefix("Elixir.", ""),
          function: to_string(function),
          arity: normalize_arity(arity),
          file: to_string(opts[:file]),
          line: opts[:line]
        }
      end

    %Stacktrace{lines: lines_params}
  end

  defp normalize_arity(a) when is_integer(a), do: a
  defp normalize_arity(a) when is_list(a), do: length(a)

  @doc """
  Source of the error stack trace.

  The first line matching the client application. If no line belongs to the current
  application, just the first line.
  """
  def source(%Stacktrace{} = stack) do
    client_app = Application.fetch_env!(:disco_log, :otp_app)

    Enum.find(stack.lines, &(&1.application == client_app)) || List.first(stack.lines)
  end
end

defimpl String.Chars, for: DiscoLog.Stacktrace do
  def to_string(%DiscoLog.Stacktrace{} = stack) do
    Enum.join(stack.lines, "\n")
  end
end

defimpl String.Chars, for: DiscoLog.Stacktrace.Line do
  def to_string(%DiscoLog.Stacktrace.Line{} = stack_line) do
    "#{stack_line.module}.#{stack_line.function}/#{stack_line.arity} in #{stack_line.file}:#{stack_line.line}"
  end
end
