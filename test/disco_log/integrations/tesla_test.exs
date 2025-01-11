defmodule DiscoLog.TeslaTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  @moduletag config: [supervisor_name: __MODULE__]

  alias DiscoLog.Integrations
  alias DiscoLog.Discord.API

  setup :setup_supervisor
  setup :attach_tesla
  setup :verify_on_exit!

  test "attaches to Tesla events" do
    assert event_attached?([:tesla, :request, :exception], DiscoLog.Integrations.Tesla)
  end

  test "send the exception with the tesla context" do
    pid = self()

    expect(API.Mock, :request, fn client, method, url, opts ->
      send(pid, opts)
      API.Stub.request(client, method, url, opts)
    end)

    execute_tesla_exception()

    assert_receive [
      {:path_params, [channel_id: "occurrences_channel_id"]},
      {:form_multipart, multipart}
    ]

    assert {context_json, [filename: "context.json"]} = multipart[:context]

    assert %{
             "method" => "get",
             "request_headers" => [],
             "response_headers" => [],
             "status" => 500,
             "url" => "http://example.com"
           } = Jason.decode!(context_json)["tesla"]

    assert %{
             "message" => %{
               "content" => _
             },
             "name" => <<_::binary-size(16)>> <> " Elixir.RuntimeError"
           } = Jason.decode!(multipart[:payload_json])
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
