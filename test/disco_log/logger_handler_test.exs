defmodule DiscoLog.LoggerHandlerTest do
  use DiscoLog.Test.Case, async: false

  require Logger

  setup :register_before_send

  test "skips logs that are not info or lower than error", %{sender_ref: ref} do
    Logger.debug("Debug message")
    Logger.warning("Warning message")

    refute_receive {^ref, _error}
  end

  test "a logged raised exception is", %{sender_ref: ref} do
    Task.start(fn ->
      raise "Unique Error"
    end)

    assert_receive {^ref, error}
    assert error.kind == to_string(RuntimeError)
    assert error.reason == "Unique Error"
  end

  defp register_before_send(_context) do
    pid = self()
    ref = make_ref()

    Application.put_env(:disco_log, :before_send, fn error ->
      send(pid, {ref, error})
      false
    end)

    %{sender_ref: ref}
  end
end
