defmodule DiscoLogTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  alias DiscoLog.Discord.API

  @moduletag config: [supervisor_name: __MODULE__]

  setup :setup_supervisor
  setup :verify_on_exit!

  describe inspect(&DiscoLog.report/5) do
    test "sends error to occurrences channel", %{config: config} do
      pid = self()

      expect(API.Mock, :request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      try do
        raise "Foo"
      catch
        kind, reason ->
          DiscoLog.report(kind, reason, __STACKTRACE__, %{}, config)
      end

      assert_receive path_params: [channel_id: "occurrences_channel_id"],
                     form_multipart: [
                       payload_json: %{name: <<_::binary-size(7)>> <> "** (RuntimeError) Foo"}
                     ]
    end

    test "uses context for metadata and tags", %{config: config} do
      pid = self()

      API.Mock
      |> expect(:request, fn client, method, url, opts ->
        send(pid, opts)
        API.Stub.request(client, method, url, opts)
      end)

      DiscoLog.Context.set(:hello, "world")
      DiscoLog.Context.set(:live_view, "foo")

      try do
        raise "Foo"
      catch
        kind, reason ->
          DiscoLog.report(kind, reason, __STACKTRACE__, %{}, config)
      end

      assert_receive path_params: [channel_id: "occurrences_channel_id"],
                     form_multipart: [
                       payload_json: %{
                         applied_tags: ["stub_live_view_tag_id"],
                         message: %{
                           components: [
                             _,
                             %{content: "```elixir\n%{hello: \"world\", live_view: \"foo\"}\n```"}
                           ]
                         }
                       }
                     ]
    end
  end
end
