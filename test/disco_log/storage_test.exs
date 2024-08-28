defmodule DiscoLog.StorageTest do
  # This is not async because it tests a singleton (the storage GenServer).
  use DiscoLog.Test.Case, async: false

  alias DiscoLog.Storage

  test "works correctly" do
    fingerprint = "fingerprint"
    thread_id = "123"

    assert Storage.add_thread_id(fingerprint, thread_id) == :ok
    assert Storage.get_thread_id(fingerprint) == thread_id
  end
end
