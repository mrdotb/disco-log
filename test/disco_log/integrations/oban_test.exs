defmodule DiscoLog.ObanTest do
  use DiscoLog.Test.Case, async: false

  alias DiscoLog.Integrations

  setup :register_before_send
  setup :attach_oban

  test "attaches to Oban events" do
    assert event_attached?([:oban, :job, :exception], DiscoLog.Integrations.Oban)
  end

  test "send the exception with the oban context", %{sender_ref: ref} do
    execute_job_exception()

    assert_receive {^ref, error}

    assert error.kind == to_string(RuntimeError)
    assert error.reason == "Exception!"
    oban = error.context["oban"]

    assert oban == %{
             "args" => %{foo: "bar"},
             "attempt" => 1,
             "id" => 123,
             "priority" => 1,
             "queue" => :default,
             "state" => :failure,
             "worker" => :"Test.Worker"
           }
  end

  defp sample_metadata do
    %{
      job: %{
        args: %{foo: "bar"},
        attempt: 1,
        id: 123,
        priority: 1,
        queue: :default,
        worker: :"Test.Worker"
      }
    }
  end

  defp execute_job_exception(additional_metadata \\ %{}) do
    raise "Exception!"
  catch
    kind, reason ->
      metadata =
        Map.merge(sample_metadata(), %{
          reason: reason,
          kind: kind,
          stacktrace: __STACKTRACE__
        })

      :telemetry.execute(
        [:oban, :job, :exception],
        %{duration: 123 * 1_000_000},
        Map.merge(metadata, additional_metadata)
      )
  end

  defp attach_oban(context) do
    Integrations.Oban.attach(true)
    context
  end
end
