defmodule DiscoLog.ObanTest do
  use DiscoLog.Test.Case, async: true

  setup :register_before_send

  test "attaches to Oban events automatically" do
    assert attached?([:oban, :job, :exception])
  end

  test "send the exception", %{sender_ref: ref} do
    execute_job_exception()

    assert_receive {^ref, error}

    assert error.kind == to_string(RuntimeError)
    assert error.reason == "Exception!"
    assert is_map(error.context.oban_job)
  end

  defp attached?(event, function \\ nil) do
    event
    |> :telemetry.list_handlers()
    |> Enum.any?(fn %{id: id} ->
      case function do
        nil -> true
        f -> function == f
      end && id == DiscoLog.Integrations.Oban
    end)
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

  defp register_before_send(_context) do
    pid = self()
    ref = make_ref()

    Application.put_env(:disco_log, :before_send, fn
      error ->
        send(pid, {ref, error})
        false
    end)

    %{sender_ref: ref}
  end
end
