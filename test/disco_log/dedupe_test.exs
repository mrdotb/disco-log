defmodule DiscoLog.DedupeTest do
  use DiscoLog.Test.Case, async: true

  alias DiscoLog.Dedupe
  alias DiscoLog.Error

  setup_all do
    Registry.start_link(keys: :unique, name: __MODULE__.Registry)
    :ok
  end

  setup do
    pid = start_link_supervised!({Dedupe, supervisor_name: __MODULE__})

    %{pid: pid}
  end

  describe inspect(&Dedupe.insert/2) do
    test "first error is new" do
      error = %Error{}

      assert Dedupe.insert(__MODULE__, error) == :new
    end

    test "then it's existing" do
      error = %Error{}

      assert Dedupe.insert(__MODULE__, error) == :new
      assert Dedupe.insert(__MODULE__, error) == :existing
      assert Dedupe.insert(__MODULE__, error) == :existing
    end
  end

  describe "sweep" do
    test "sweep cleans up table", %{pid: pid} do
      error = %Error{}

      assert Dedupe.insert(__MODULE__, error) == :new
      assert Dedupe.insert(__MODULE__, error) == :existing

      # Now, we trigger a sweep after waiting for the TTL interval.
      # To ensure the :sweep message is processed, we use the trick
      # of asking the GenServer for its state (which is a sync call).
      send(pid, {:sweep, 0})
      _ = :sys.get_state(pid)

      # Now, it's :new again.
      assert Dedupe.insert(__MODULE__, error) == :new
    end
  end
end
