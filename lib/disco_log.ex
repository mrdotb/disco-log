defmodule DiscoLog do
  @moduledoc """
  Elixir-based built-in error tracking solution.
  """
  def report(exception, stacktrace, given_context \\ %{}, config \\ nil) do
    config = config || DiscoLog.Config.read!()
    context = Map.merge(DiscoLog.Context.get(), given_context)

    error = DiscoLog.Error.new(exception, stacktrace, context, config.otp_app)
    DiscoLog.Client.send_error(error, config)
  end
end
