defmodule DiscoLog.TeslaTest do
  use DiscoLog.Test.Case, async: false

  alias DiscoLog.Integrations

  setup :register_before_send
  setup :attach_tesla

  test "attaches to Tesla events" do
    assert event_attached?([:tesla, :request, :exception], DiscoLog.Integrations.Tesla)
  end

  test "send the exception with the tesla context", %{sender_ref: ref} do
    execute_tesla_exception()

    assert_receive {^ref, error}

    assert error.kind == to_string(RuntimeError)
    assert error.reason == "Exception!"
    assert is_map(error.context["tesla"])
  end

  defp execute_tesla_exception do
    raise "Exception!"
  catch
    kind, reason ->
      :telemetry.execute(
        [:tesla, :request, :exception],
        %{duration: 123 * 1_000_000},
        %{
          kind: kind,
          reason: reason,
          stacktrace: __STACKTRACE__,
          env: %Env{
            method: :get,
            url: "http://example.com",
            status: 500,
            response_headers: [],
            request_headers: []
          }
        }
      )
  end

  defp attach_tesla(context) do
    Integrations.Tesla.attach(true)
    context
  end
end
