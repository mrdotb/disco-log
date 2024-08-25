defmodule DiscoLog do
  @moduledoc """
  Elixir-based built-in error tracking solution.
  """

  def report(exception, stacktrace, given_context \\ %{}) do
    context = Map.merge(DiscoLog.Context.get(), given_context)

    error = DiscoLog.Error.new(exception, stacktrace, context)
    DiscoLog.Client.send_error(error)
  end
end
