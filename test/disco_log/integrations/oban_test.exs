defmodule DiscoLog.ObanTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  @moduletag config: [supervisor_name: __MODULE__]

  alias DiscoLog.Integrations
  alias DiscoLog.Discord.API

  setup :setup_supervisor
  setup :attach_oban
  setup :verify_on_exit!

  test "attaches to Oban events" do
    assert event_attached?([:oban, :job, :exception], DiscoLog.Integrations.Oban)
  end

  test "send the exception with the oban context" do
    pid = self()

    expect(API.Mock, :request, fn client, method, url, opts ->
      send(pid, opts)
      API.Stub.request(client, method, url, opts)
    end)

    execute_job_exception()

    assert_receive [
      {:path_params, [channel_id: "occurrences_channel_id"]},
      {:form_multipart, multipart}
    ]

    assert {context_json, [filename: "context.json"]} = multipart[:context]

    assert %{
             "args" => %{"foo" => "bar"},
             "attempt" => 1,
             "id" => 123,
             "priority" => 1,
             "queue" => "default",
             "state" => "failure",
             "worker" => "Test.Worker"
           } = Jason.decode!(context_json)["oban"]

    assert %{
             "message" => %{
               "content" => _
             },
             "name" => <<_::binary-size(16)>> <> " Elixir.RuntimeError"
           } = Jason.decode!(multipart[:payload_json])
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
    Integrations.Oban.attach(context.config, true)
    context
  end
end
