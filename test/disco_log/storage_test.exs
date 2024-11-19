defmodule DiscoLog.StorageTest do
  use DiscoLog.Test.Case, async: true

  import Mox

  alias DiscoLog.Storage
  alias DiscoLog.DiscordMock

  setup :verify_on_exit!

  setup_all do
    Registry.start_link(keys: :unique, name: __MODULE__.Registry)
    :ok
  end

  describe "start_link" do
    test "loads occurences on startup" do
      expect(DiscordMock, :list_occurrence_threads, fn _config, channel_id ->
        assert channel_id == "channel_id"

        [{"fingerprint", "thread_id"}]
      end)

      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken", occurrences_channel_id: "channel_id"},
             discord: DiscordMock
           ]}
        )

      _ = :sys.get_status(pid)

      assert [{pid, %{"fingerprint" => "thread_id"}}] ==
               Registry.lookup(__MODULE__.Registry, Storage)
    end
  end

  describe inspect(&Storage.get_thread_id/2) do
    setup do
      stub(DiscordMock, :list_occurrence_threads, fn _, _ -> [{"fingerprint", "thread_id"}] end)

      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken", occurrences_channel_id: "channel_id"},
             discord: DiscordMock
           ]}
        )

      _ = :sys.get_status(pid)
      :ok
    end

    test "thread id exists" do
      assert "thread_id" = Storage.get_thread_id(__MODULE__, "fingerprint")
    end

    test "nil if missing" do
      assert nil == Storage.get_thread_id(__MODULE__, "unknown")
    end
  end

  describe inspect(&Storage.add_thread_id/3) do
    setup do
      stub(DiscordMock, :list_occurrence_threads, fn _, _ -> [{"fingerprint", "thread_id"}] end)

      pid =
        start_link_supervised!(
          {Storage,
           [
             supervisor_name: __MODULE__,
             discord_config: %{token: "mytoken", occurrences_channel_id: "channel_id"},
             discord: DiscordMock
           ]}
        )

      _ = :sys.get_status(pid)
      :ok
    end

    test "puts new thread" do
      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "bar")

      assert [{_, %{"foo" => "bar"}}] =
               Registry.lookup(__MODULE__.Registry, Storage)
    end

    test "overwrites thread_id" do
      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "bar")

      assert [{_, %{"foo" => "bar"}}] =
               Registry.lookup(__MODULE__.Registry, Storage)

      assert :ok = Storage.add_thread_id(__MODULE__, "foo", "baz")

      assert [{_, %{"foo" => "baz"}}] =
               Registry.lookup(__MODULE__.Registry, Storage)
    end
  end
end
