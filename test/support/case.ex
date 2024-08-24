defmodule DiscoLog.Test.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import DiscoLog.Test.Case
    end
  end

  @doc """
  Builds an error produced by the given function.
  """
  def build_error(fun) do
    fun.()
  rescue
    exception ->
      DiscoLog.Error.new(exception, __STACKTRACE__, %{})
  catch
    kind, reason ->
      DiscoLog.Error.new({kind, reason}, __STACKTRACE__, %{})
  end

  @doc """
  Reports the error produced by the given function.
  """
  def report_error(fun) do
    occurrence =
      try do
        fun.()
      rescue
        exception ->
          DiscoLog.report(exception, __STACKTRACE__)
      catch
        kind, reason ->
          DiscoLog.report({kind, reason}, __STACKTRACE__)
      end

    occurrence
  end

  @doc """
  Sends telemetry events as messages to the current process.

  This allows test cases to check that telemetry events are fired with:

      assert_receive {:telemetry_event, event, measurements, metadata}
  """
  def attach_telemetry do
    :telemetry.attach_many(
      "telemetry-test",
      [
        [:disco_log, :error, :new],
        [:disco_log, :error, :resolved],
        [:disco_log, :error, :unresolved],
        [:disco_log, :occurrence, :new]
      ],
      &__MODULE__._send_telemetry/4,
      nil
    )
  end

  def _send_telemetry(event, measurements, metadata, _opts) do
    send(self(), {:telemetry_event, event, measurements, metadata})
  end
end
