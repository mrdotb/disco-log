defmodule DiscoLog.TeslaTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  @moduletag config: [supervisor_name: __MODULE__]

  alias DiscoLog.Integrations
  alias DiscoLog.DiscordMock

  setup :setup_supervisor
  setup :attach_tesla
  setup :verify_on_exit!

  test "attaches to Tesla events" do
    assert event_attached?([:tesla, :request, :exception], DiscoLog.Integrations.Tesla)
  end

  test "send the exception with the tesla context" do
    pid = self()
    ref = make_ref()

    expect(DiscordMock, :create_occurrence_thread, fn _config, error ->
      send(pid, {ref, error})
    end)

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
    Integrations.Tesla.attach(context.config, true)
    context
  end
end
