defmodule DiscoLog.StorageTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  alias DiscoLog.Storage
  alias DiscoLog.Discord.API

  setup :verify_on_exit!

  setup_all do
    Registry.start_link(keys: :unique, name: __MODULE__.Registry)
    :ok
  end

  describe "start_link" do
    test "loads occurrences and tags on startup" do
      API.Mock
      |> expect(:request, 2, fn
        client, :get, "/guilds/:guild_id/threads/active", opts ->
          assert [path_params: [guild_id: "guild_id"]] = opts
          API.Stub.request(client, :get, "/guilds/:guild_id/threads/active", [])

        client, :get, "/channels/:channel_id", opts ->
          assert [path_params: [channel_id: "stub_occurrences_channel_id"]] = opts
          API.Stub.request(client, :get, "/channels/:channel_id", [])
      end)

      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             occurrences_channel_id: "stub_occurrences_channel_id",
             guild_id: "guild_id",
             discord_client: %API{module: API.Mock}
           ]}
        )

      _ = :sys.get_status(pid)

      assert [{pid, %{"FNGRPT" => "stub_thread_id"}}] ==
               Registry.lookup(__MODULE__.Registry, {Storage, :threads})

      assert [
               {pid,
                %{
                  "oban" => "stub_oban_tag_id",
                  "live_view" => "stub_live_view_tag_id",
                  "plug" => "stub_plug_tag_id"
                }}
             ] ==
               Registry.lookup(__MODULE__.Registry, {Storage, :tags})
    end
  end

  describe inspect(&Storage.get_thread_id/2) do
    setup do
      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             occurrences_channel_id: "stub_occurrences_channel_id",
             guild_id: "guild_id",
             discord_client: %API{module: API.Mock}
           ]}
        )

      _ = :sys.get_status(pid)
      :ok
    end

    test "thread id exists" do
      assert "stub_thread_id" = Storage.get_thread_id(__MODULE__, "FNGRPT")
    end

    test "nil if missing" do
      assert nil == Storage.get_thread_id(__MODULE__, "unknown")
    end
  end

  describe inspect(&Storage.add_thread_id/3) do
    setup do
      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             occurrences_channel_id: "stub_occurrences_channel_id",
             guild_id: "guild_id",
             discord_client: %API{module: API.Mock}
           ]}
        )

      _ = :sys.get_status(pid)
      :ok
    end

    test "puts new thread" do
      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "bar")

      assert [{_, %{"foo" => "bar"}}] =
               Registry.lookup(__MODULE__.Registry, {Storage, :threads})
    end

    test "overwrites thread_id" do
      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "bar")

      assert [{_, %{"foo" => "bar"}}] =
               Registry.lookup(__MODULE__.Registry, {Storage, :threads})

      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "baz")

      assert [{_, %{"foo" => "baz"}}] =
               Registry.lookup(__MODULE__.Registry, {Storage, :threads})
    end
  end

  describe inspect(&Storage.get_tags/1) do
    setup do
      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             occurrences_channel_id: "stub_occurrences_channel_id",
             guild_id: "guild_id",
             discord_client: %API{module: API.Mock}
           ]}
        )

      _ = :sys.get_status(pid)
      :ok
    end

    test "retrieves all tags" do
      assert %{
               "oban" => "stub_oban_tag_id",
               "live_view" => "stub_live_view_tag_id",
               "plug" => "stub_plug_tag_id"
             } == Storage.get_tags(__MODULE__)
    end
  end
end
