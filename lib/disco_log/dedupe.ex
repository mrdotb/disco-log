defmodule DiscoLog.Dedupe do
  @moduledoc """
  Dedupe module to prevent reporting error multiple times.

  Original implementation from Sentry Elixir
  https://github.com/getsentry/sentry-elixir/blob/69ac8d0e3f33ff36ab1092bbd346fdb99cf9d061/lib/sentry/dedupe.ex
  """
  use GenServer

  alias DiscoLog.Error

  defstruct [:table, ttl_millisec: 30_000, sweep_interval_millisec: 10_000]

  ## Public API

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    name =
      opts
      |> Keyword.fetch!(:supervisor_name)
      |> DiscoLog.Registry.via(__MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec insert(atom(), Error.t()) :: :new | :existing
  def insert(name, %Error{} = error) do
    [{_, table}] =
      name
      |> DiscoLog.Registry.registry_name()
      |> Registry.lookup(__MODULE__)

    hash = Error.hash(error)
    now = System.system_time(:millisecond)

    cond do
      _found? = :ets.update_element(table, hash, {_position = 2, now}) -> :existing
      _inserted_new? = :ets.insert_new(table, {hash, now}) -> :new
      true -> :existing
    end
  end

  ## Callbacks

  @impl GenServer
  def init(opts) do
    table = :ets.new(__MODULE__, [:public, :set])

    opts[:supervisor_name]
    |> DiscoLog.Registry.registry_name()
    |> Registry.update_value(__MODULE__, fn _ -> table end)

    state = struct(__MODULE__, opts ++ [table: table])

    schedule_sweep(state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info({:sweep, ttl_millisec}, state) do
    now = System.system_time(:millisecond)

    # All rows (which are {hash, inserted_at}) with an inserted_at older than
    # now - ttl_millisec.
    match_spec = [{{:"$1", :"$2"}, [], [{:"=<", :"$2", now - ttl_millisec}]}]
    _ = :ets.select_delete(state.table, match_spec)

    schedule_sweep(state)
    {:noreply, state}
  end

  ## Helpers

  defp schedule_sweep(%__MODULE__{
         ttl_millisec: ttl_millisec,
         sweep_interval_millisec: sweep_interval_millisec
       }) do
    Process.send_after(self(), {:sweep, ttl_millisec}, sweep_interval_millisec)
  end
end
