defmodule DiscoLog.Stacktrace do
  @moduledoc """
  A struct that contains the information about the execution stack for a given
  occurrence of an exception.
  """

  alias __MODULE__

  defmodule Line do
    @moduledoc false

    @type t :: %__MODULE__{
            application: String.t(),
            module: String.t(),
            top_module: String.t(),
            function: String.t(),
            arity: non_neg_integer(),
            file: String.t() | nil,
            line: non_neg_integer() | nil
          }
    defstruct ~w(application module top_module function arity file line)a
  end

  @type t :: %Stacktrace{
          lines: [Line.t()]
        }

  defstruct ~w(lines)a

  def new(stack) do
    lines_params =
      for {module, function, arity, opts} <- stack do
        application = Application.get_application(module)
        module_string = to_string(module) |> String.replace_prefix("Elixir.", "")

        %Line{
          application: to_string(application),
          module: module_string,
          top_module: module_string |> String.split(".") |> hd(),
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
  def source(%Stacktrace{} = stack, client_app) do
    Enum.find(stack.lines, &(&1.application == client_app)) || List.first(stack.lines)
  end

  @doc """
  Source of the error stack trace if it belongs to the given application.
  """
  def app_source(%Stacktrace{} = stack, client_app, top_modules) do
    Enum.find(stack.lines, &(&1.application == client_app || &1.top_module in top_modules))
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
