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
  Asserts that the given telemetry event is attached to the given module.
  """
  def event_attached?(event, module) do
    event
    |> :telemetry.list_handlers()
    |> Enum.any?(fn %{id: id} -> id == module end)
  end

  @doc """
  Setup a register before send function for testing purposes.
  """
  def register_before_send(context) do
    pid = self()
    ref = make_ref()

    Application.put_env(:disco_log, :before_send, fn
      error ->
        send(pid, {ref, error})
        # prevent the discord log to be send by return false
        false
    end)

    Map.put(context, :sender_ref, ref)
  end
end
