defmodule DiscoLog.PlugTest do
  use DiscoLog.Test.Case, async: true

  import Mox
  require Logger
  alias DiscoLog.Discord.API

  @moduletag config: [supervisor_name: __MODULE__]

  setup {LoggerHandlerKit.Arrange, :ensure_per_handler_translation}

  setup :setup_supervisor
  setup :setup_logger_handler
  setup :verify_on_exit!

  defmodule AppRouter do
    use Plug.Router

    plug(DiscoLog.Integrations.Plug)
    plug(:match)
    plug(:dispatch)

    forward("/", to: LoggerHandlerKit.Plug)
  end

  describe "Bandit" do
    test "plug exception", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, 2, fn
        client, method, url, [{:path_params, [channel_id: "info_channel_id"]} | _] = opts ->
          API.Stub.request(client, method, url, opts)

        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:exception, Bandit, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Kind:** `RuntimeError`
                       **Reason:** `oops`
                       **Source:** \
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end

    test "plug throw", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, 2, fn
        client, method, url, [{:path_params, [channel_id: "info_channel_id"]} | _] = opts ->
          API.Stub.request(client, method, url, opts)

        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:throw, Bandit, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Reason:** `** (throw) \"catch!\"`
                       **Source:** \
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end

    test "plug exit", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, 2, fn
        client, method, url, [{:path_params, [channel_id: "info_channel_id"]} | _] = opts ->
          API.Stub.request(client, method, url, opts)

        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:exit, Bandit, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Reason:** `** (exit) \"i quit\"`
                       **Source:** \
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end
  end

  describe "Cowboy" do
    test "plug exception", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn
        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:exception, Plug.Cowboy, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Kind:** `RuntimeError`
                       **Reason:** `oops`
                       **Source:** \
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end

    test "plug throw", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn
        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:throw, Plug.Cowboy, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Reason:** `** (throw) \"catch!\"`
                       **Source:** \
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end

    test "plug exit", %{handler_ref: ref} do
      pid = self()

      expect(API.Mock, :request, fn
        client, method, url, opts ->
          send(pid, opts)
          API.Stub.request(client, method, url, opts)
      end)

      LoggerHandlerKit.Act.plug_error(:exit, Plug.Cowboy, AppRouter)
      LoggerHandlerKit.Assert.assert_logged(ref)

      assert_receive [
        {:path_params, [channel_id: "occurrences_channel_id"]},
        {:form_multipart, [payload_json: body]}
      ]

      assert %{
               applied_tags: ["stub_plug_tag_id"],
               message: %{
                 components: [
                   %{
                     type: 10,
                     content:
                       """
                       **Reason:** `** (exit) \"i quit\"`\
                       """ <> _
                   },
                   %{}
                 ]
               }
             } = body
    end
  end
end
