defmodule DiscoLog.DedupeTest do
  # This is not async because it tests a singleton (the dedupe GenServer).
  use DiscoLog.Test.Case, async: false

  alias DiscoLog.Dedupe
  alias DiscoLog.Error

  describe inspect(&Dedupe.insert/1) do
    test "works correctly" do
      error = %Error{}

      # First time, it's :new.
      assert Dedupe.insert(error) == :new

      # Then, it's :existing.
      assert Dedupe.insert(error) == :existing
      assert Dedupe.insert(error) == :existing

      # Now, we trigger a sweep after waiting for the TTL interval.
      # To ensure the :sweep message is processed, we use the trick
      # of asking the GenServer for its state (which is a sync call).
      Process.sleep(5)
      send(Dedupe, {:sweep, 0})
      _ = :sys.get_state(Dedupe)

      # Now, it's :new again.
      assert Dedupe.insert(error) == :new
      assert Dedupe.insert(error) == :existing
    end
  end
end
