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
      {:form_multipart, [payload_json: body]}
    ]

    assert %{
             name: <<_::binary-size(7)>> <> "** (RuntimeError) Exception!",
             applied_tags: ["stub_oban_tag_id"],
             message: %{
               components: [
                 %{
                   content: "**Kind:** `RuntimeError`\n**Reason:** `Exception!`" <> _
                 },
                 %{
                   content: "```\n** (RuntimeError) Exception!\n" <> _
                 },
                 %{
                   type: 10,
                   content:
                     "```elixir\n%{\n  \"oban\" => %{\n    \"args\" => %{foo: \"bar\"},\n    \"attempt\" => 1,\n    \"id\" => 123,\n    \"priority\" => 1,\n    \"queue\" => :default,\n    \"state\" => :failure,\n    \"worker\" => :\"Test.Worker\"\n  }\n}\n```"
                 }
               ]
             }
           } = body
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
