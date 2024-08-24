defmodule DiscoLog.Dedupe do
  @moduledoc """
  Dedupe module to prevent reporting error multiple times.

  Original implementation from Sentry Elixir
  https://github.com/getsentry/sentry-elixir/blob/69ac8d0e3f33ff36ab1092bbd346fdb99cf9d061/lib/sentry/dedupe.ex
  """
  use GenServer

  alias DiscoLog.Error

  @ets __MODULE__
  @sweep_interval_millisec 10_000
  @ttl_millisec 30_000

  ## Public API

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link([] = _opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec insert(Error.t()) :: :new | :existing
  def insert(%Error{} = error) do
    hash = Error.hash(error)
    now = System.system_time(:millisecond)

    cond do
      _found? = :ets.update_element(@ets, hash, {_position = 2, now}) -> :existing
      _inserted_new? = :ets.insert_new(@ets, {hash, now}) -> :new
      true -> :existing
    end
  end

  ## Callbacks

  @impl true
  def init(nil) do
    _table = :ets.new(@ets, [:named_table, :public, :set])
    schedule_sweep()
    {:ok, :no_state}
  end

  @impl true
  def handle_info({:sweep, ttl_millisec}, state) do
    now = System.system_time(:millisecond)

    # All rows (which are {hash, inserted_at}) with an inserted_at older than
    # now - @ttl_millisec.
    match_spec = [{{:"$1", :"$2"}, [], [{:<, :"$2", now - ttl_millisec}]}]
    _ = :ets.select_delete(@ets, match_spec)

    schedule_sweep()
    {:noreply, state}
  end

  ## Helpers

  defp schedule_sweep do
    Process.send_after(self(), {:sweep, @ttl_millisec}, @sweep_interval_millisec)
  end
end
